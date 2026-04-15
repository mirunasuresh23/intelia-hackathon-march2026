import os
import functions_framework
from google.cloud import storage
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)

@functions_framework.http
def archive_gcs_files(request):
    """HTTP Cloud Function to move CSV delta batches to the archive/ folder."""
    request_json = request.get_json(silent=True)
    bucket_name = request_json.get("bucket_name") if request_json else None
    
    # Fall back to environment variable if not provided in JSON
    if not bucket_name:
        bucket_name = os.environ.get("BRONZE_BUCKET")
        
    if not bucket_name:
        return ({"error": "Missing bucket_name"}, 400)

    client = storage.Client()
    bucket = client.bucket(bucket_name)
    archive_bucket = client.bucket("miruna-intelia-hackathon-archive-files")

    # Target table bases
    targets = ["customers", "products", "orders", "order_items"]
    baseline_files = [f"{t}.csv" for t in targets]
    
    total_moved = 0
    # Search the root of the bucket
    blobs = bucket.list_blobs()
    
    for blob in blobs:
        # Ignore things that aren't CSVs
        if not blob.name.endswith(".csv"):
            continue
            
        # Ignore things already safely packed in the archive/ directory
        if blob.name.startswith("archive/"):
            continue
            
        # Ensure it actually belongs to one of our tracked Data Warehouse tables
        if not any(t in blob.name for t in targets):
            continue
            
        # IMPORTANT: Keep the initial baseline .csv files permanently at the root!
        # If we delete the baselines, BigQuery external tables will crash on missing source_uris.
        # Dataform's CDC QUALIFY deduplication safely ignores baselines once swallowed anyway!
        if blob.name in baseline_files:
            continue
            
        # Generate timestamp to avoid strict object overwrites in archive
        arch_time = datetime.utcnow().strftime("%Y%m%d%H%M%S")
        archive_name = f"{arch_time}_{blob.name}"
        logging.info(f"Archiving Delta Batch: Moving {blob.name} -> gs://miruna-intelia-hackathon-archive-files/{archive_name}")
        
        # Copy to archive bucket and safely delete original delta
        bucket.copy_blob(blob, archive_bucket, archive_name)
        blob.delete()
        total_moved += 1
            
    return ({"status": "success", "files_moved": total_moved}, 200)
