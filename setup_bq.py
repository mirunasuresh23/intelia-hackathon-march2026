from google.cloud import bigquery

def create_dataset(project_id, dataset_id):
    client = bigquery.Client(project=project_id)
    dataset_ref = client.dataset(dataset_id)
    
    try:
        client.get_dataset(dataset_ref)
        print(f"Dataset {dataset_id} already exists.")
    except Exception:
        dataset = bigquery.Dataset(dataset_ref)
        dataset.location = "US"  # Adjust location if needed
        dataset = client.create_dataset(dataset)
        print(f"Dataset {dataset_id} created.")

if __name__ == "__main__":
    PROJECT_ID = "miruna-sandpit"
    DATASET_ID = "intelia_dwh"
    create_dataset(PROJECT_ID, DATASET_ID)
