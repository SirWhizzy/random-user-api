
import random
import time
from datetime import datetime
import os
import pandas as pd
import requests
from sqlalchemy import create_engine



# Configuration
BASE_URL = "https://randomuser.me/api/"
BATCH_SIZE = 10
TOTAL_RECORDS = random.randint(5, 10)
response = requests.get(BASE_URL, params={'results': TOTAL_RECORDS})
response.raise_for_status()
data = response.json()
output = data['results']

#print(f"output: {output}")

# RDS connection config (set these as environment variables for security)
DB_USER = os.getenv('RDS_USER', 'rds_user')
DB_PASS = os.getenv('RDS_PASS', '9mN(Nj[5][x_')
DB_HOST = os.getenv('RDS_HOST', 'randomuser-db-instance.ck7ms4gc8zph.us-east-1.rds.amazonaws.com')
DB_PORT = os.getenv('RDS_PORT', "5432")  # Default PostgreSQL port
DB_NAME = os.getenv('RDS_DB', 'random_user')
DB_TYPE = os.getenv('RDS_TYPE', 'postgresql') # e.g., 'postgresql', 'mysql', etc.

def fetch_random_users(total_records=10):
    """
    Fetch random user data from randomuser.me API and return as a DataFrame.
    """
    BASE_URL = "https://randomuser.me/api/"
    
    # Make request
    response = requests.get(BASE_URL, params={"results": total_records})
    response.raise_for_status()  # Raise an error if request failed
    
    # Parse JSON
    data = response.json()["results"]
    
    # Flatten and load into DataFrame
    df = pd.json_normalize(data)
    
    return df

# Example usage:
#df = fetch_random_users(total_records=3)
#print(df.head())



def upload_to_rds():
    '''Write the DataFrame to an RDS PostgreSQL database'''
    DB_USER = os.getenv('RDS_USER', 'rds_user')
    DB_PASS = os.getenv('RDS_PASS', '9mN(Nj[5][x_')
    DB_HOST = os.getenv('RDS_HOST', 'randomuser-db-instance.ck7ms4gc8zph.us-east-1.rds.amazonaws.com')
    DB_PORT = os.getenv('RDS_PORT', "5432")  # Default PostgreSQL port
    DB_NAME = os.getenv('RDS_DB', 'random_user')
    DB_TYPE = os.getenv('RDS_TYPE', 'postgresql') # e.g., 'postgresql', 'mysql', etc.

    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    df = fetch_random_users()
    df.to_sql("random_user_tbl",engine,if_exists="replace",index=False,method="multi")
    
    print(f"✅ Uploaded {len(df)} rows to {"random_user_tbl"}")


#df = fetch_random_users(total_records=20)
#upload_to_rds(df, table_name="random_user_tbl")