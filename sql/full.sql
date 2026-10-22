
------------------------------------------------------------------
--RAW TABLES
select *
from raw.games;

select *
from raw.players;

select *
from raw.earn_events;

select *
from raw.redeem_events;

select *
from raw.fx_rates;

------------------------------------------------------------------
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

------------------------------------------------------------------
--FINAL VIEWS
select *
from analytics.monthly_earned;

select *
from analytics.monthly_redeemed;

select *
from analytics.monthly_redeemed_by_game;

select *
from analytics.monthly_outstanding_float;
