import logging
from google.cloud import bigquery

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

PROJECT_ID = "miruna-sandpit"

def apply_governance():
    client = bigquery.Client(project=PROJECT_ID)
    
    # Dataset descriptions
    datasets = {
        "dwh_bronze": "Raw landing zone for GCS files. Data is untransformed.",
        "dwh_silver": "Staged and cleaned data. Deduplicated and typed.",
        "dwh_gold": "Curated business layer with aggregates and AI enrichment."
    }
    
    for ds_id, desc in datasets.items():
        dataset = client.get_dataset(ds_id)
        dataset.description = desc
        dataset.labels = {"governance": "intelia_hackathon", "owner": "miruna_suresh"}
        client.update_dataset(dataset, ["description", "labels"])
        logging.info(f"Applied governance to dataset {ds_id}.")

    # Table descriptions (Example for Products)
    table_id = f"{PROJECT_ID}.dwh_silver.products"
    table = client.get_table(table_id)
    table.description = "Cleaned product master data with categories and prices."
    client.update_table(table, ["description"])
    logging.info(f"Applied governance to table {table_id}.")

if __name__ == "__main__":
    apply_governance()
