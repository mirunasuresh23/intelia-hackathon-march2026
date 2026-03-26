import functions_framework
from google.cloud import bigquery
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)

PROJECT_ID = "miruna-sandpit"
DATASET_ID = "dwh_bronze"

@functions_framework.cloud_event
def gcs_to_bigquery_trigger(cloud_event):
    """Triggered by a change to a Cloud Storage bucket."""
    data = cloud_event.data
    bucket = data["bucket"]
    file_name = data["name"]
    
    # We only care about our specific files for this demo
    expected_files = ["customers.csv", "products.csv", "order_items.csv", "orders.csv"]
    if file_name not in expected_files:
        logging.info(f"Skipping file {file_name} as it is not in the expected list.")
        return

    client = bigquery.Client(project=PROJECT_ID)
    table_name = file_name.replace(".csv", "")
    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    uri = f"gs://{bucket}/{file_name}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND # Delta loads usually append
    )

    logging.info(f"Processing {file_name} from bucket {bucket}...")
    
    try:
        load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
        load_job.result()
        logging.info(f"Successfully appended {file_name} to {table_id}.")
    except Exception as e:
        logging.error(f"Error loading {file_name}: {e}")
