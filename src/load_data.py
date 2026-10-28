import os
import time
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import URL, Engine, create_engine, text

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'data'

TABLES = [
    {'table': 'customers', 'file_name': 'olist_customers_dataset.csv', 'options': {'dtype': {'customer_zip_code_prefix': str}}},
    {'table': 'orders', 'file_name': 'olist_orders_dataset.csv', 'options': {'parse_dates': ["order_purchase_timestamp", "order_approved_at", "order_delivered_carrier_date", "order_delivered_customer_date", "order_estimated_delivery_date"]}},
    {'table': 'products', 'file_name': 'olist_products_dataset.csv', 'options': {}, 'rename_columns': {'product_name_lenght': 'product_name_length', 'product_description_lenght': 'product_description_length'}},
    {'table': 'sellers', 'file_name': 'olist_sellers_dataset.csv', 'options': {'dtype': {'seller_zip_code_prefix': str}}},
    {'table': 'product_category_name_translation', 'file_name': 'product_category_name_translation.csv', 'options': {}},
    {'table': 'order_items', 'file_name': 'olist_order_items_dataset.csv', 'options': {'parse_dates': ['shipping_limit_date']}},
    {'table': 'order_payments', 'file_name': 'olist_order_payments_dataset.csv', 'options': {}},
    {'table': 'order_reviews', 'file_name': 'olist_order_reviews_dataset.csv', 'options': {'parse_dates': ['review_creation_date', 'review_answer_timestamp']}},
    {'table': 'geolocation', 'file_name': 'olist_geolocation_dataset.csv', 'options': {'dtype': {'geolocation_zip_code_prefix': str}}},
]


def make_engine() -> Engine:
    load_dotenv()

    user = os.environ['DB_USER']
    host = os.environ['DB_HOST']
    password = os.environ['DB_PASS']
    port = int(os.environ['DB_PORT'])
    database = os.environ['DB_NAME']

    url = URL.create(drivername='mysql+pymysql', username=user, password=password, host=host, port=port, database=database)
    engine = create_engine(url)

    return engine


def check_connection(engine: Engine):
    with engine.connect() as conn:
        res1 = conn.execute(text('SELECT VERSION()'))
        res2 = conn.execute(text('SELECT DATABASE()'))
        res3 = conn.execute(text('SHOW TABLES'))

        print(res1.scalar())
        print(res2.scalar())
        print(res3.fetchall())


def load_table(engine: Engine, table: str, file_name: str, rename_columns: dict, **read_kwargs):
    path = DATA / file_name
    df = pd.read_csv(path, **read_kwargs)

    if len(rename_columns) > 0:
        df = df.rename(columns=rename_columns)

    df_count = len(df)

    db_count = get_row_count(engine, table)

    if db_count < 1:
        t0 = time.perf_counter()
        df.to_sql(table, engine, if_exists="append", index=False, chunksize=2000)
        elapsed = time.perf_counter() - t0
        print(f"took {elapsed:.2f}s")
        db_count = get_row_count(engine, table)
    else:
        print(f'{table} Data already exists. Rerun "schema.sql".')

    if df_count != db_count:
        raise ValueError(f"Both counts don't match for {table}. CSV has {df_count} and db has {db_count}")

    check_table(engine, table)


def check_table(engine: Engine, table: str):
    with engine.connect() as conn:
        db_count = conn.execute(text(f'SELECT COUNT(*) FROM {table}')).scalar()
        print(f'{table} db:', db_count)
        conn.commit()


def get_row_count(engine: Engine, table: str) -> int:
    db_count = 0
    with engine.connect() as conn:
        db_count = conn.execute(text(f'SELECT COUNT(*) FROM {table}')).scalar()
        conn.commit()

    return db_count


def main():
    engine = make_engine()
    check_connection(engine)

    for table_entry in TABLES:
        load_table(engine, table_entry['table'], table_entry['file_name'], table_entry.get('rename_columns', {}), **table_entry['options'])


if __name__ == '__main__':
    main()
