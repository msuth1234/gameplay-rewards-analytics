
--STAGING VIEWS
select *
from staging.stg_players;

select *
from staging.stg_games;

select *
from staging.stg_earn_events;

select *
from staging.stg_redeem_events;

select *
from staging.stg_redemption_history;

select *
from staging.stg_fx_rates;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_earn_events AS
SELECT DISTINCT ON (earn_id)
    event_id,
    earn_id,
    player_id,
    game_id,
    earned_at::timestamp AS earned_at,
    amount::numeric AS amount,
    currency,
    earn_type
FROM raw.earn_events
ORDER BY earn_id, earned_at::timestamp, event_id;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_redeem_events AS
SELECT DISTINCT ON (redemption_id)
    log_id,
    redemption_id,
    player_id,
    channel,
    status,
    amount::numeric AS amount,
    currency,
    status_changed_at::timestamp AS status_changed_at
FROM raw.redeem_events
ORDER BY
    redemption_id,
    status_changed_at DESC,
    log_id DESC;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_fx_rates AS
SELECT
    currency,
    rate_date::date AS rate_date,
    rate_to_usd::numeric AS rate_to_usd
FROM raw.fx_rates;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_games AS
SELECT
    game_id,
    game_name,
    platform,
    primary_region,
    launch_date::date AS launch_date
FROM raw.games;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_players AS
SELECT
    player_id,
    signup_date::date AS signup_date,
    region,
    primary_game_id,
    status,
    updated_at::timestamp AS updated_at
FROM raw.players;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW staging.stg_redemption_history AS
SELECT
    redemption_id,
    player_id,
    channel,
    amount::numeric AS amount,
    currency,
    MIN(status_changed_at::timestamp) FILTER (WHERE status = 'requested') AS requested_at,
    MIN(status_changed_at::timestamp) FILTER (WHERE status = 'settled') AS settled_at,
    MIN(status_changed_at::timestamp) FILTER (WHERE status = 'reversed') AS reversed_at,
    MAX(status_changed_at::timestamp) AS latest_status_at
FROM raw.redeem_events
GROUP BY
    redemption_id,
    player_id,
    channel,
    amount,
    currency;
    