import awswrangler as wr
from generate_records import generate_data
from aws_session import aws_session
import pandas as pd


records = generate_data(10)
df = pd.DataFrame(records)


wr.s3.to_csv(
    df=df,
    path="s3://tolu-de-buckets/random_users/",
    boto3_session=aws_session(),
    mode="overwrite",
    dataset=True
    )

