# Intelia Hackathon - Data Warehouse Deployment

This repository contains the infrastructure and data transformation code to deploy a BigQuery Data Warehouse using Terraform and Dataform.

## Overview

The project is structured to automatically provision data warehousing infrastructure on Google Cloud Platform and orchestrate the transformation of bronze (raw) data into silver and gold layers. 

### Key Components

- **Terraform (`terraform/`)**: Infrastructure-as-code to provision BigQuery datasets (`dwh_bronze`, `dwh_silver`, `dwh_gold`), set up external tables connected to GCS, and create a Dataform repository for data transformations.
- **Dataform (`definitions/`)**: SQLX scripts defining the transformations from bronze raw tables to clean silver tables and enriched gold views.
- **Python Pipelines**: Helper scripts like `deploy_dwh.py`, `run_pipeline.py`, and `setup_bq.py` for orchestrating the overall pipeline, configuring endpoints, and applying governance.
- **SQL Queries**: Extra analytical queries available in `genai_queries.sql` and `transform_to_silver.sql`.

## Setup Instructions

### 1. Provision Infrastructure with Terraform
Navigate to the `terraform/` directory and apply the configuration.
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Deploy the Dataform Repository
After Terraform has completed provisioning the `dwh_bronze`, `dwh_silver`, and `dwh_gold` datasets, Dataform will use the files in `definitions/` to build your dependency tree. 

### 3. Run the Python Pipeline
You can trigger data ingestion and dataform execution manually or integrate it into your orchestrator.
```bash
pip install -r requirements.txt # (If you have dependencies)
python run_pipeline.py
```

## Data Lineage
- **Bronze**: External tables connected directly to Cloud Storage (Customers, Products, Orders, Order Items).
- **Silver**: Cleansed and strictly-typed tables managed by Dataform.
- **Gold**: Aggregated analytical datasets (e.g. `gold_revenue_by_category`, `gold_ai_enriched_products`).
