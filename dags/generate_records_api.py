
import random
import time
from datetime import datetime
import os
import pandas as pd
import requests
from sqlalchemy import create_engine

# Configuration
BASE_URL = "https://randomuser.me/api/"
BATCH_SIZE = 5000
TOTAL_RECORDS = random.randint(5_000, 10_000)

# RDS connection config (set these as environment variables for security)
DB_USER = os.getenv('RDS_USER', 'your_username')
DB_PASS = os.getenv('RDS_PASS', 'your_password')
DB_HOST = os.getenv('RDS_HOST', 'your_host')
DB_PORT = os.getenv('RDS_PORT', '5432')  # Default PostgreSQL port
DB_NAME = os.getenv('RDS_DB', 'your_dbname')
DB_TYPE = os.getenv('RDS_TYPE', 'postgresql')  # e.g., 'postgresql', 'mysql', etc.

def get_engine():
    """
    Create a SQLAlchemy engine for the RDS instance.
    Returns:
        sqlalchemy.engine.Engine: SQLAlchemy engine object.
    """
    conn_str = f"{DB_TYPE}://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(conn_str)

def fetch_batch(batch_size):
    """
    Fetch a batch of random users from the API.
    Args:
        batch_size (int): Number of users to fetch in this batch.
    Returns:
        list: List of user dictionaries from the API response.
    Raises:
        requests.RequestException: If the API request fails.
    """
    response = requests.get(BASE_URL, params={'results': batch_size})
    response.raise_for_status()
    data = response.json()
    return data['results']

def normalize_result(user):
    """
    Flatten a single user dictionary from the API into a flat dictionary for DataFrame use.
    Args:
        user (dict): Nested user dictionary from API.
    Returns:
        dict: normalized dictionary with selected user fields.
    """
    return {
        'first_name': user['name']['first'],
        'last_name': user['name']['last'],
        'email': user['email'],
        'gender': user['gender'],
        'city': user['location']['city'],
        'country': user['location']['country'],
        'dob': user['dob']['date'],
        'age': user['dob']['age'],
        'registered': user['registered']['date']
    }


def fetch_data(total_records):
    """
    Fetch the specified number of user records in batches, normalize, and return as a DataFrame.
    Args:
        total_records (int): Total number of user records to fetch.
    Returns:
        pd.DataFrame: DataFrame containing all user records.
    """
    all_data = []
    retrieved = 0

    while retrieved < total_records:
        batch_size = min(BATCH_SIZE, total_records - retrieved)
        print(f"Fetching {batch_size} records... ({retrieved:,}/{total_records:,})")

        try:
            batch = fetch_batch(batch_size)
            normalized = [normalize_result(user) for user in batch]
            all_data.extend(normalized)
            retrieved += batch_size
            time.sleep(1)  # increased delay to avoid rate-limiting
        except requests.exceptions.HTTPError as e:
            if e.response is not None and e.response.status_code == 429:
                print("Rate limit hit. Waiting 10 seconds before retrying...")
                time.sleep(10)
            else:
                print(f"HTTP error: {e}. Retrying in 5s...")
                time.sleep(5)
        except Exception as e:
            print(f"Error fetching batch: {e}. Retrying in 5s...")
            time.sleep(5)

    return pd.DataFrame(all_data)

def load_to_rds(df, table_name='random_users', if_exists='append'):
    """
    Load the DataFrame into the specified RDS table using SQLAlchemy.
    Args:
        df (pd.DataFrame): DataFrame to load.
        table_name (str): Target table name in RDS.
        if_exists (str): 'replace', 'append', or 'fail'.
    """
    engine = get_engine()
    print(f"Loading {len(df)} records to RDS table '{table_name}'...")
    df.to_sql(table_name, engine, if_exists=if_exists, index=False, method='multi')
    print(f"✅ Data loaded to RDS table '{table_name}'.")


# Execution
if __name__ == "__main__":
    print(f"Starting data fetch for {TOTAL_RECORDS:,} random users...")
    df = fetch_data(TOTAL_RECORDS)
    load_to_rds(df)
