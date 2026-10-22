--Product wants a monthly view of earned value, redeemed value, and outstanding float, broken out by game and redemption channel.

--FINAL VIEWS
select *
from analytics.monthly_earned;

select *
from analytics.monthly_redeemed;

select *
from analytics.monthly_redeemed_by_game;

select *
from analytics.monthly_outstanding_float;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.monthly_earned AS
select
    date_trunc('month', e.earned_at)::date earned_month,
    e.game_id,
    g.game_name,
    sum(e.amount * fx.rate_to_usd) earned_value_usd,
    count(*) earn_count
from staging.stg_earn_events e
join staging.stg_fx_rates fx on fx.currency = e.currency and fx.rate_date = date_trunc('month', e.earned_at)::date
left join staging.stg_games g on g.game_id = e.game_id
group by 1,2,3;


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.monthly_redeemed AS
with settlements as 
(select date_trunc('month', settled_at)::date id_month,
channel,
currency,
amount,
redemption_id
from staging.stg_redemption_history
where settled_at is not null),

reversals as 
(select date_trunc('month', reversed_at)::date id_month,
channel,
currency,
amount * -1 amount,
redemption_id
from staging.stg_redemption_history
where reversed_at is not null),

redemption_base as 
(select * from settlements 
union all
select * from reversals)

select 
id_month,
channel,
sum(r.amount * fx.rate_to_usd) redeemed_value_usd,
count(*) redemption_events
from redemption_base r
join staging.stg_fx_rates fx on fx.currency = r.currency and fx.rate_date = r.id_month
group by 1,2


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.monthly_redeemed_by_game AS
with settlements as 
(select date_trunc('month', settled_at)::date id_month,
channel,
currency,
amount,
redemption_id,
player_id
from staging.stg_redemption_history
where settled_at is not null),

reversals as 
(select date_trunc('month', reversed_at)::date id_month,
channel,
currency,
amount * -1 amount,
redemption_id,
player_id
from staging.stg_redemption_history
where reversed_at is not null),

redemption_base as 
(select *
from settlements 
union all
select * from reversals)

select 
id_month,
g.game_name primary_game_name,
channel,
sum(r.amount * fx.rate_to_usd) redeemed_value_usd
from redemption_base r
join staging.stg_fx_rates fx on fx.currency = r.currency and fx.rate_date = r.id_month
left join staging.stg_players p on p.player_id = r.player_id
left join staging.stg_games g on g.game_id = p.primary_game_id
group by 1,2,3


------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.monthly_outstanding_float AS
with earned as 
(select 
earned_month,
game_id,
game_name,
earned_value_usd
from analytics.monthly_earned),

redeemed as 
(select
id_month,
primary_game_name,
SUM(redeemed_value_usd) total_redeemed_value_usd
from analytics.monthly_redeemed_by_game
group by 1,2),

float_values_base as 
(select 
earned_month,
game_id,
game_name,
coalesce(earned_value_usd,0) earned_value_usd,
id_month,
primary_game_name,
coalesce(total_redeemed_value_usd,0) total_redeemed_value_usd
from earned e 
full join redeemed r on r.id_month = e.earned_month and r.primary_game_name = e.game_name),

final_float_values as
(select coalesce(earned_month,id_month) id_month,
coalesce(game_name,primary_game_name) game_name,
earned_value_usd,
total_redeemed_value_usd,
(earned_value_usd - total_redeemed_value_usd) month_float_amount_usd
from float_values_base)

select *,
SUM(month_float_amount_usd) OVER (
        PARTITION BY game_name
        ORDER BY id_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS outstanding_float_usd
from final_float_values;
