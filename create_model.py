import time
from google.cloud import bigquery

client = bigquery.Client(project="miruna-sandpit")
query = """
CREATE OR REPLACE MODEL `miruna-sandpit.dwh_silver.gemini_model`
REMOTE WITH CONNECTION `miruna-sandpit.us.vertex-ai-conn`
OPTIONS(ENDPOINT = 'gemini-1.0-pro');
"""

try:
    job = client.query(query)
    job.result()
    print("Model created successfully.")
except Exception as e:
    print(f"Error: {e}")
