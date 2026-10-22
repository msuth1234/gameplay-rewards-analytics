
--Check row and id counts
select 'players' table_name, count(*) total_count,count(distinct player_id) id_1,count(distinct primary_game_id) id_2,null::bigint id_3
from raw.players
union all
select 'games' table_name, count(*),count(distinct game_id),null::bigint,null::bigint
from raw.games
union all
select 'earn_events' table_name, count(*),count(distinct event_id),count(distinct earn_id),null::bigint
from raw.earn_events
union all
select 'redeem_events' table_name, count(*),count(distinct log_id),count(distinct redemption_id),count(distinct player_id)
from raw.redeem_events
union all
select 'fx_rates' table_name, count(*),count(distinct currency || rate_date),null::bigint,null::bigint
from raw.fx_rates;

--find dupe earn_ids
select earn_id
from raw.earn_events
group by 1
having count(*) > 1;

--spot check earn_id data
select *
from raw.earn_events
where earn_id in ('E003310','E003311','E004171','E006704')
order by earn_id, earned_at;


--check dates/date ranges
select 'earn_events' table_name,
min(earned_at::timestamp) AS earliest_date,
max(earned_at::timestamp) AS latest_date,
count(*) filter (where earned_at is null) null_dates
from raw.earn_events

union all

select 'redeem_events',
min(status_changed_at::timestamp),
max(status_changed_at::timestamp),
count(*) filter (where status_changed_at is null)
from raw.redeem_events;


-- Gaming Rewards Analytics: Validation Tests
-- Expected results are noted for each check.

-- 1. Staged earn IDs should be unique.
-- Expected: 0 rows.
SELECT earn_id, COUNT(*) AS row_count
FROM staging.stg_earn_events
GROUP BY earn_id
HAVING COUNT(*) > 1;


-- 2. Redemption history should have one row per redemption.
-- Expected: 0 rows.
SELECT redemption_id, COUNT(*) AS row_count
FROM staging.stg_redemption_history
GROUP BY redemption_id
HAVING COUNT(*) > 1;


-- 3. Earn events should have a matching monthly FX rate.
-- Expected: 0 rows.
SELECT e.earn_id, e.currency, e.earned_at
FROM staging.stg_earn_events e
LEFT JOIN staging.stg_fx_rates fx
  ON fx.currency = e.currency
 AND fx.rate_date = DATE_TRUNC('month', e.earned_at)::date
WHERE fx.currency IS NULL;


-- 4. Redemption flows should have a matching monthly FX rate.
-- Expected: 0 rows.
WITH redemption_flows AS (
    SELECT currency, settled_at AS flow_at
    FROM staging.stg_redemption_history
    WHERE settled_at IS NOT NULL

    UNION ALL

    SELECT currency, reversed_at AS flow_at
    FROM staging.stg_redemption_history
    WHERE reversed_at IS NOT NULL
)
SELECT r.currency, r.flow_at
FROM redemption_flows r
LEFT JOIN staging.stg_fx_rates fx
  ON fx.currency = r.currency
 AND fx.rate_date = DATE_TRUNC('month', r.flow_at)::date
WHERE fx.currency IS NULL;


-- 5. Validate monthly earned totals and overall total.
-- Expected: 6 monthly rows; overall total should be $261,057.08.

SELECT
    earned_month,
    ROUND(SUM(earned_value_usd), 2) AS earned_value_usd
FROM analytics.monthly_earned
GROUP BY earned_month
ORDER BY earned_month;

SELECT ROUND(SUM(earned_value_usd), 2) AS total_earned_usd
FROM analytics.monthly_earned;



-- 6. Redeemed totals should reconcile between the channel
-- model and game attribution model.
-- Expected: 0 rows; overall total should be $39,315.69.

WITH channel_totals AS (
    SELECT SUM(redeemed_value_usd) AS total_usd
    FROM analytics.monthly_redeemed
),
game_totals AS (
    SELECT SUM(redeemed_value_usd) AS total_usd
    FROM analytics.monthly_redeemed_by_game
)
SELECT
    ROUND(c.total_usd, 2) AS channel_total_usd,
    ROUND(g.total_usd, 2) AS game_total_usd
FROM channel_totals c
CROSS JOIN game_totals g
WHERE ROUND(c.total_usd, 2) <> ROUND(g.total_usd, 2);



-- 7. The outstanding-float model should have one row per
-- month and game.
-- Expected: 0 rows.
SELECT id_month, game_name, COUNT(*) AS row_count
FROM analytics.monthly_outstanding_float
GROUP BY id_month, game_name
HAVING COUNT(*) > 1;


-- 8. Expected reporting coverage: six months and 18 games.
-- Expected: 6 distinct months, 18 distinct games, 108 rows.
SELECT COUNT(DISTINCT id_month) AS month_count,
       COUNT(DISTINCT game_name) AS game_count,
       COUNT(*) AS row_count
FROM analytics.monthly_outstanding_float;


-- 9. Outstanding float should not be negative under the
-- cumulative earned-minus-net-redeemed definition.
-- Expected: 0 rows.
SELECT id_month, game_name, outstanding_float_usd
FROM analytics.monthly_outstanding_float
WHERE outstanding_float_usd < -0.01;


-- 10. Reversals should occur after settlements.
-- Expected: 0 rows.
SELECT redemption_id, settled_at, reversed_at
FROM staging.stg_redemption_history
WHERE reversed_at IS NOT NULL
  AND (
      settled_at IS NULL
      OR reversed_at <= settled_at
  );


-- 11. Known data-quality exception: earn records without
-- a matching player. These are retained in earned totals.
-- Expected: 52 rows. 14 missing.
SELECT COUNT(*) AS earn_rows_without_matching_player,
       COUNT(DISTINCT e.player_id) AS distinct_missing_player_ids
FROM staging.stg_earn_events e
LEFT JOIN staging.stg_players p
  ON p.player_id = e.player_id
WHERE p.player_id IS NULL;

SELECT distinct e.player_id,p.player_id
FROM staging.stg_earn_events e
LEFT JOIN staging.stg_players p
  ON p.player_id = e.player_id
WHERE p.player_id IS NULL;


-- 12. Redemption history consistency.
-- Expected: 0 rows.

SELECT redemption_id
FROM raw.redeem_events
GROUP BY redemption_id
HAVING COUNT(DISTINCT player_id) > 1
    OR COUNT(DISTINCT channel) > 1
    OR COUNT(DISTINCT amount) > 1
    OR COUNT(DISTINCT currency) > 1;



-- 13. Outstanding float should equal cumulative earned
-- minus cumulative net redeemed for each game.
-- Expected: 0 rows, allowing for minor rounding differences.

WITH expected AS (
    SELECT
        id_month,
        game_name,
        SUM(earned_value_usd - total_redeemed_value_usd)
            OVER (
                PARTITION BY game_name
                ORDER BY id_month
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS expected_float_usd
    FROM analytics.monthly_outstanding_float
)
SELECT
    f.id_month,
    f.game_name,
    f.outstanding_float_usd,
    e.expected_float_usd
FROM analytics.monthly_outstanding_float f
JOIN expected e
  ON e.id_month = f.id_month
 AND e.game_name = f.game_name
WHERE ABS(f.outstanding_float_usd - e.expected_float_usd) > 0.01;
