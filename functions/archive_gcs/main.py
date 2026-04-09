import os
import functions_framework
from google.cloud import storage
import logging

logging.basicConfig(level=logging.INFO)

@functions_framework.http
def archive_gcs_files(request):
    """HTTP Cloud Function to move CSV files to the archive/ folder."""
    request_json = request.get_json(silent=True)
    bucket_name = request_json.get("bucket_name") if request_json else None
    
    # We can also fall back to environment variable if not provided
    if not bucket_name:
        bucket_name = os.environ.get("BRONZE_BUCKET")
        
    if not bucket_name:
        return ("Missing bucket_name", 400)

    client = storage.Client()
    bucket = client.bucket(bucket_name)

    # Prefix directories where data lands (as defined in our external tables)
    prefixes = ["customers/", "products/", "orders/", "order_items/"]
    
    total_moved = 0
    for prefix in prefixes:
        blobs = bucket.list_blobs(prefix=prefix)
        for blob in blobs:
            if not blob.name.endswith(".csv"):
                continue
                
            archive_name = f"archive/{blob.name}"
            logging.info(f"Moving {blob.name} to {archive_name}")
            
            # Copy and delete to simulate a move
            bucket.copy_blob(blob, bucket, archive_name)
            blob.delete()
            total_moved += 1
            
    return ({"status": "success", "files_moved": total_moved}, 200)
