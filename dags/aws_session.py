import os
import boto3
from dotenv import load_dotenv

load_dotenv()


def aws_session():
    session = boto3.Session(
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_REGION'))
    return session

