# Data Dictionary


### `games`

* `game_id`: identifier for the game
* `game_name`: descriptive name of the game
* `platform`: name of the platform the game is published on
* `primary_region`: the main geography the game operates in
* `launch_date`: date the game went live

### `players`

* `player_id`: identifier for the player
* `signup_date`: when the player signed up for the game
* `region`: the geography the player registered from
* `primary_game_id`: the main game the player plays, based on event signals
* `status`: the player's account status
* `updated_at`: timestamp this record was last written

### `earn_events`

* `event_id`: identifier assigned to the record by the event collection pipeline
* `earn_id`: identifier assigned to the earn action by the source rewards system
* `player_id`: foreign key for which player earned the reward
* `game_id`: foreign key for which game the reward was earned on
* `earned_at`: timestamp the reward was earned
* `amount`: value of the reward
* `currency`: denomination of the reward
* `earn_type`: category of the earn action (such as gameplay, tournament, bonus)

### `redeem_events`

* `log_id`: identifier for this redemption event entry
* `redemption_id`: identifier for the redemption request
* `player_id`: foreign key for which player the redemption belongs to
* `channel`: what channel the redemption request is for
* `status`: status of the redemption at the time of this log entry (requested, settled, failed, reversed)
* `amount`: value of the redemption
* `currency`: denomination of the redemption
* `status_changed_at`: timestamp of the status change

### `fx_rates`
* `currency`: currency code
* `rate_date`: date the rate snapshot was captured
* `rate_to_usd`: conversion rate from the given currency to USD as of that date