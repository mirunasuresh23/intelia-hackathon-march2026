import logging
from google.cloud import bigquery
from google.api_core import exceptions

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

PROJECT_ID = "miruna-sandpit"
LOCATION = "US"
DATASETS = ["dwh_bronze", "dwh_silver", "dwh_gold"]

# Schema Definitions
SCHEMAS = {
    "customers": [
        bigquery.SchemaField("customer_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("first_name", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("last_name", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("email", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("phone", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("date_of_birth", "DATE", mode="NULLABLE"),
        bigquery.SchemaField("gender", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("registration_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("country", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("city", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("acquisition_channel", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("customer_tier", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("is_email_subscribed", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("is_sms_subscribed", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("preferred_device", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("preferred_category", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("loyalty_points", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("account_status", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("last_login_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("referral_source_id", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("marketing_segment", "STRING", mode="NULLABLE"),
    ],
    "products": [
        bigquery.SchemaField("product_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("sku", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("product_name", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("category", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("subcategory", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("brand", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("unit_cost", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("unit_price", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("discount_eligible", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("stock_quantity", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("weight_kg", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("supplier_id", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("is_active", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("created_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("last_updated_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("average_rating", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("review_count", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("return_rate", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("tags", "STRING", mode="NULLABLE"),
    ],
    "orders": [
        bigquery.SchemaField("order_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("customer_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("order_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("order_status", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("payment_method", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("payment_status", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("shipping_address_country", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("shipping_address_city", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("shipping_method", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("shipping_cost", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("subtotal", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("discount_code", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("discount_amount", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("tax_amount", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("total_amount", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("session_id", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("device_type", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("acquisition_channel_at_order", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("coupon_used", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("is_first_order", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("fulfillment_center", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("estimated_delivery_date", "TIMESTAMP", mode="NULLABLE"),
        bigquery.SchemaField("actual_delivery_date", "TIMESTAMP", mode="NULLABLE"),
    ],
    "order_items": [
        bigquery.SchemaField("order_item_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("order_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("product_id", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("quantity", "INTEGER", mode="NULLABLE"),
        bigquery.SchemaField("unit_price_at_purchase", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("discount_applied", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("line_total", "FLOAT", mode="NULLABLE"),
        bigquery.SchemaField("is_returned", "BOOLEAN", mode="NULLABLE"),
        bigquery.SchemaField("return_reason", "STRING", mode="NULLABLE"),
        bigquery.SchemaField("return_date", "TIMESTAMP", mode="NULLABLE"),
    ]
}

def setup_dwh():
    client = bigquery.Client(project=PROJECT_ID)

    # 1. Create Datasets
    for dataset_id in DATASETS:
        dataset_ref = bigquery.DatasetReference(PROJECT_ID, dataset_id)
        try:
            client.get_dataset(dataset_ref)
            logging.info(f"Dataset {dataset_id} already exists.")
        except exceptions.NotFound:
            dataset = bigquery.Dataset(dataset_ref)
            dataset.location = LOCATION
            client.create_dataset(dataset)
            logging.info(f"Dataset {dataset_id} created.")

    # 2. Create Tables in Bronze and Silver
    for dataset_id in ["dwh_bronze", "dwh_silver"]:
        for table_name, schema in SCHEMAS.items():
            table_id = f"{PROJECT_ID}.{dataset_id}.{table_name}"
            
            if dataset_id == "dwh_bronze":
                # Create External Table for Bronze
                external_config = bigquery.ExternalConfig("CSV")
                external_config.source_uris = [f"gs://miruna-intelia-hackathon-files/{table_name}.csv"]
                external_config.options.skip_leading_rows = 1
                external_config.autodetect = True
                
                table = bigquery.Table(table_id)
                table.external_data_configuration = external_config
            else:
                # Create Native Table for Silver with explicit schema
                table = bigquery.Table(table_id, schema=schema)
            
            try:
                client.get_table(table_id)
                logging.info(f"Table {table_id} already exists.")
            except exceptions.NotFound:
                client.create_table(table)
                logging.info(f"Table {table_id} created.")

    logging.info("Infrastructure setup complete.")

if __name__ == "__main__":
    setup_dwh()
