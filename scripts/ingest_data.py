import pandas as pd
import psycopg2
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://postgres:pgpassword@localhost:5432/gameplay_rewards"
)


files = [
    "earn_events",
    "fx_rates",
    "games",
    "players",
    "redeem_events"
]


for file in files:

    df = pd.read_csv(
        f"C:/Users/Michelle/Projects/gameplay_rewards/data/{file}.csv"
    )

    df.to_sql(
        file,
        engine,
        schema="raw",
        if_exists="replace",
        index=False
    )

    print(f"Loaded {file}: {len(df)} rows")
    