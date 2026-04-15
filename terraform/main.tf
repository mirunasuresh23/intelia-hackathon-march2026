terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket  = "miruna-intelia-hackathon-source-code"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# 1. Enable APIs
resource "google_project_service" "bigquery" {
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "dataform" {
  service = "dataform.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloudscheduler" {
  service = "cloudscheduler.googleapis.com"
}

# 2. Secret Manager for Dataform Git Auth
resource "google_secret_manager_secret" "dataform_git_auth" {
  secret_id = "dataform-git-auth"
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
    }
  }
  depends_on = [google_project_service.secretmanager]
}

# 3. Datasets
resource "google_bigquery_dataset" "bronze" {
  dataset_id = "dwh_bronze"
  location   = var.region
  depends_on = [google_project_service.bigquery]
}

resource "google_bigquery_dataset" "silver" {
  dataset_id = "dwh_silver"
  location   = var.region
  depends_on = [google_project_service.bigquery]
}

resource "google_bigquery_dataset" "gold" {
  dataset_id = "dwh_gold"
  location   = var.region
  depends_on = [google_project_service.bigquery]
}

# 4. External Tables (Bronze)
# Example for Customers
resource "google_bigquery_table" "bronze_customers" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "customers"
  schema = <<EOF
[
  {"name": "customer_id", "type": "STRING"},
  {"name": "first_name", "type": "STRING"},
  {"name": "last_name", "type": "STRING"},
  {"name": "email", "type": "STRING"},
  {"name": "phone", "type": "STRING"},
  {"name": "date_of_birth", "type": "DATE"},
  {"name": "gender", "type": "STRING"},
  {"name": "registration_date", "type": "TIMESTAMP"},
  {"name": "country", "type": "STRING"},
  {"name": "city", "type": "STRING"},
  {"name": "acquisition_channel", "type": "STRING"},
  {"name": "customer_tier", "type": "STRING"},
  {"name": "is_email_subscribed", "type": "BOOLEAN"},
  {"name": "is_sms_subscribed", "type": "BOOLEAN"},
  {"name": "preferred_device", "type": "STRING"},
  {"name": "preferred_category", "type": "STRING"},
  {"name": "loyalty_points", "type": "INTEGER"},
  {"name": "account_status", "type": "STRING"},
  {"name": "last_login_date", "type": "TIMESTAMP"},
  {"name": "referral_source_id", "type": "STRING"},
  {"name": "marketing_segment", "type": "STRING"},
  {"name": "_delta_type", "type": "STRING"},
  {"name": "_batch_id", "type": "STRING"},
  {"name": "_batch_date", "type": "STRING"}
]
EOF

  deletion_protection = false
  external_data_configuration {
    autodetect            = false
    ignore_unknown_values = true
    source_format         = "CSV"
    source_uris   = [
      "gs://${var.bucket_name}/customers.csv",
      "gs://${var.bucket_name}/*_customers_delta.csv"
    ]
    csv_options {
      allow_jagged_rows = true
      skip_leading_rows = 1
      quote             = "\""
    }
  }
}

# (Repeat for other tables or use a dynamic block/module in a real enterprise setup)
# For brevity in this hackathon, we'll implement the others similarly.

resource "google_bigquery_table" "bronze_products" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "products"
  schema = <<EOF
[
  {"name": "product_id", "type": "STRING"},
  {"name": "sku", "type": "STRING"},
  {"name": "product_name", "type": "STRING"},
  {"name": "category", "type": "STRING"},
  {"name": "subcategory", "type": "STRING"},
  {"name": "brand", "type": "STRING"},
  {"name": "unit_cost", "type": "FLOAT"},
  {"name": "unit_price", "type": "FLOAT"},
  {"name": "discount_eligible", "type": "BOOLEAN"},
  {"name": "stock_quantity", "type": "INTEGER"},
  {"name": "weight_kg", "type": "FLOAT"},
  {"name": "supplier_id", "type": "STRING"},
  {"name": "is_active", "type": "BOOLEAN"},
  {"name": "created_date", "type": "DATE"},
  {"name": "last_updated_date", "type": "DATE"},
  {"name": "average_rating", "type": "FLOAT"},
  {"name": "review_count", "type": "INTEGER"},
  {"name": "return_rate", "type": "FLOAT"},
  {"name": "tags", "type": "STRING"},
  {"name": "_delta_type", "type": "STRING"},
  {"name": "_batch_id", "type": "STRING"},
  {"name": "_batch_date", "type": "STRING"}
]
EOF

  deletion_protection = false
  external_data_configuration {
    autodetect            = false
    ignore_unknown_values = true
    source_format         = "CSV"
    source_uris   = [
      "gs://${var.bucket_name}/products.csv",
      "gs://${var.bucket_name}/*_products_delta.csv"
    ]
    csv_options { 
      allow_jagged_rows = true
      skip_leading_rows = 1 
      quote             = "\""
    }
  }
}

resource "google_bigquery_table" "bronze_orders" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "orders"
  schema = <<EOF
[
  {"name": "order_id", "type": "STRING"},
  {"name": "customer_id", "type": "STRING"},
  {"name": "order_date", "type": "TIMESTAMP"},
  {"name": "order_status", "type": "STRING"},
  {"name": "payment_method", "type": "STRING"},
  {"name": "payment_status", "type": "STRING"},
  {"name": "shipping_address_country", "type": "STRING"},
  {"name": "shipping_address_city", "type": "STRING"},
  {"name": "shipping_method", "type": "STRING"},
  {"name": "shipping_cost", "type": "FLOAT"},
  {"name": "subtotal", "type": "FLOAT"},
  {"name": "discount_code", "type": "STRING"},
  {"name": "discount_amount", "type": "FLOAT"},
  {"name": "tax_amount", "type": "FLOAT"},
  {"name": "total_amount", "type": "FLOAT"},
  {"name": "session_id", "type": "STRING"},
  {"name": "device_type", "type": "STRING"},
  {"name": "acquisition_channel_at_order", "type": "STRING"},
  {"name": "coupon_used", "type": "BOOLEAN"},
  {"name": "is_first_order", "type": "BOOLEAN"},
  {"name": "fulfillment_center", "type": "STRING"},
  {"name": "estimated_delivery_date", "type": "DATE"},
  {"name": "actual_delivery_date", "type": "DATE"},
  {"name": "_delta_type", "type": "STRING"},
  {"name": "_batch_id", "type": "STRING"},
  {"name": "_batch_date", "type": "STRING"}
]
EOF

  deletion_protection = false
  external_data_configuration {
    autodetect            = false
    ignore_unknown_values = true
    source_format         = "CSV"
    source_uris   = [
      "gs://${var.bucket_name}/orders.csv",
      "gs://${var.bucket_name}/*_orders_delta.csv"
    ]
    csv_options { 
      allow_jagged_rows = true
      skip_leading_rows = 1 
      quote             = "\""
    }
  }
}

resource "google_bigquery_table" "bronze_order_items" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "order_items"
  schema = <<EOF
[
  {"name": "order_item_id", "type": "STRING"},
  {"name": "order_id", "type": "STRING"},
  {"name": "product_id", "type": "STRING"},
  {"name": "quantity", "type": "INTEGER"},
  {"name": "unit_price_at_purchase", "type": "FLOAT"},
  {"name": "discount_applied", "type": "FLOAT"},
  {"name": "line_total", "type": "FLOAT"},
  {"name": "is_returned", "type": "BOOLEAN"},
  {"name": "return_reason", "type": "STRING"},
  {"name": "return_date", "type": "DATE"},
  {"name": "_delta_type", "type": "STRING"},
  {"name": "_batch_id", "type": "STRING"},
  {"name": "_batch_date", "type": "STRING"}
]
EOF

  deletion_protection = false
  external_data_configuration {
    autodetect            = false
    ignore_unknown_values = true
    source_format         = "CSV"
    source_uris   = [
      "gs://${var.bucket_name}/order_items.csv",
      "gs://${var.bucket_name}/*_order_items_delta.csv"
    ]
    csv_options { 
      skip_leading_rows = 1 
      quote             = "\""
    }
  }
}

# 5. Native Tables (Silver)
resource "google_bigquery_table" "silver_customers" {
  dataset_id = google_bigquery_dataset.silver.dataset_id
  table_id   = "customers"
  deletion_protection = false
  schema     = <<EOF
[
  {"name": "customer_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "first_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "last_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "email", "type": "STRING", "mode": "NULLABLE"},
  {"name": "phone", "type": "STRING", "mode": "NULLABLE"},
  {"name": "date_of_birth", "type": "DATE", "mode": "NULLABLE"},
  {"name": "gender", "type": "STRING", "mode": "NULLABLE"},
  {"name": "registration_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "country", "type": "STRING", "mode": "NULLABLE"},
  {"name": "city", "type": "STRING", "mode": "NULLABLE"},
  {"name": "acquisition_channel", "type": "STRING", "mode": "NULLABLE"},
  {"name": "customer_tier", "type": "STRING", "mode": "NULLABLE"},
  {"name": "is_email_subscribed", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "is_sms_subscribed", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "preferred_device", "type": "STRING", "mode": "NULLABLE"},
  {"name": "preferred_category", "type": "STRING", "mode": "NULLABLE"},
  {"name": "loyalty_points", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "account_status", "type": "STRING", "mode": "NULLABLE"},
  {"name": "last_login_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "referral_source_id", "type": "STRING", "mode": "NULLABLE"},
  {"name": "marketing_segment", "type": "STRING", "mode": "NULLABLE"},
  {"name": "load_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"}
]
EOF
}

resource "google_bigquery_table" "silver_products" {
  dataset_id = google_bigquery_dataset.silver.dataset_id
  table_id   = "products"
  deletion_protection = false
  schema     = <<EOF
[
  {"name": "product_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "sku", "type": "STRING", "mode": "NULLABLE"},
  {"name": "product_name", "type": "STRING", "mode": "NULLABLE"},
  {"name": "category", "type": "STRING", "mode": "NULLABLE"},
  {"name": "subcategory", "type": "STRING", "mode": "NULLABLE"},
  {"name": "brand", "type": "STRING", "mode": "NULLABLE"},
  {"name": "unit_cost", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "unit_price", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "discount_eligible", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "stock_quantity", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "weight_kg", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "supplier_id", "type": "STRING", "mode": "NULLABLE"},
  {"name": "is_active", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "created_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "last_updated_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "average_rating", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "review_count", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "return_rate", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "tags", "type": "STRING", "mode": "NULLABLE"},
  {"name": "load_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"}
]
EOF
}

resource "google_bigquery_table" "silver_orders" {
  dataset_id = google_bigquery_dataset.silver.dataset_id
  table_id   = "orders"
  deletion_protection = false
  schema     = <<EOF
[
  {"name": "order_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "customer_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "order_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "order_status", "type": "STRING", "mode": "NULLABLE"},
  {"name": "payment_method", "type": "STRING", "mode": "NULLABLE"},
  {"name": "payment_status", "type": "STRING", "mode": "NULLABLE"},
  {"name": "shipping_address_country", "type": "STRING", "mode": "NULLABLE"},
  {"name": "shipping_address_city", "type": "STRING", "mode": "NULLABLE"},
  {"name": "shipping_method", "type": "STRING", "mode": "NULLABLE"},
  {"name": "shipping_cost", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "subtotal", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "discount_code", "type": "STRING", "mode": "NULLABLE"},
  {"name": "discount_amount", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "tax_amount", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "total_amount", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "session_id", "type": "STRING", "mode": "NULLABLE"},
  {"name": "device_type", "type": "STRING", "mode": "NULLABLE"},
  {"name": "acquisition_channel_at_order", "type": "STRING", "mode": "NULLABLE"},
  {"name": "coupon_used", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "is_first_order", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "fulfillment_center", "type": "STRING", "mode": "NULLABLE"},
  {"name": "estimated_delivery_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "actual_delivery_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "load_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"}
]
EOF
}

resource "google_bigquery_table" "silver_order_items" {
  dataset_id = google_bigquery_dataset.silver.dataset_id
  table_id   = "order_items"
  deletion_protection = false
  schema     = <<EOF
[
  {"name": "order_item_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "order_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "product_id", "type": "STRING", "mode": "REQUIRED"},
  {"name": "quantity", "type": "INTEGER", "mode": "NULLABLE"},
  {"name": "unit_price_at_purchase", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "discount_applied", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "line_total", "type": "FLOAT", "mode": "NULLABLE"},
  {"name": "is_returned", "type": "BOOLEAN", "mode": "NULLABLE"},
  {"name": "return_reason", "type": "STRING", "mode": "NULLABLE"},
  {"name": "return_date", "type": "TIMESTAMP", "mode": "NULLABLE"},
  {"name": "load_timestamp", "type": "TIMESTAMP", "mode": "NULLABLE"}
]
EOF
}

# 6. Dataform Repository
resource "google_dataform_repository" "repo" {
  provider = google-beta
  name     = "intelia-hackathon-repo"
  project  = var.project_id
  region   = "us-central1"

  git_remote_settings {
    url                                 = var.git_repo_url
    default_branch                      = "main"
    authentication_token_secret_version = "${google_secret_manager_secret.dataform_git_auth.id}/versions/latest"
  }

  depends_on = [google_project_service.dataform]
}
