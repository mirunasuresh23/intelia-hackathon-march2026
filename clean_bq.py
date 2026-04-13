from google.cloud import bigquery
import logging

logging.basicConfig(level=logging.INFO)
client = bigquery.Client(project="miruna-sandpit")

datasets = ["dwh_bronze", "dwh_silver"]

for ds in datasets:
    dataset_id = f"miruna-sandpit.{ds}"
    try:
        logging.info(f"Deleting dataset {dataset_id}...")
        client.delete_dataset(dataset_id, delete_contents=True, not_found_ok=True)
        logging.info(f"Deleted {dataset_id}.")
    except Exception as e:
        logging.error(f"Failed to delete {dataset_id}: {e}")
