# Analytics Engineering Take-Home

### Context:

You're joining the team supporting a player rewards program. Players earn value through gameplay, and can redeem it for real-world value through a few different channels. In this repo, there are 5 CSVs representing the underlying system:

- `games.csv`
- `players.csv`
- `earn_events.csv`
- `redeem_events.csv`
- `fx_rates.csv`

The system was built quickly and hasn't had much data modeling attention. Treat the data as you would in a real, if imperfect, production system.

#### Data Dictionary

You have access to a high-level data dictionary, described at `DATA_DICTIONARY.md`.

### The ask

Product wants a monthly view of earned value, redeemed value, and outstanding float, broken out by game and redemption channel. Build the data model and any transforms needed, and prepare a version of the output you'd actually hand to Product.

### Deliverables

Your deliverables are:

1. A schema/ERD sketch of the model you built
2. Working SQL models (dbt or otherwise) of any intermediate or final data models, along with any tests you created
3. The monthly breakdown itself, in a form ready to discuss with a stakeholder (e.g. chart, table, etc.)
4. A short written brief covering any assumptions you made along the way, any data quality issues you ran into and how you handled them, what you'd want to confirm with stakeholders if you could ask, how you used AI tools during this exercise, and what you'd do differently with more time.

To submit the exercise, please create a repository (Github or otherwise) with your work and notify us via candidate email. If you have questions or issues with the submission mechanism, please also let us know and we can find alternatives if necessary.

### Guidance

#### Tooling

Use whatever tools you would normally use, including AI. We're evaluating your judgement and choices along the way, not whether you typed every line by hand.

#### Timing

Aim for about 2 hours. This isn't a hard cutoff. If you are meaningfully over that, let us know where you are and why, rather than grinding or speeding to finish everything.

#### Live discussion

After submitting, the next step will be a live discussion with members of the team. You should come to the live session prepared to screen share your working environment and run queries against the data live, not just talk through what you did. Any queryable set up works, e.g. SQLite, DuckDB, local relational database, or an online SQL sandbox are all fine. There's no required tool, but you should be prepared to pull up your work and query it in real time.