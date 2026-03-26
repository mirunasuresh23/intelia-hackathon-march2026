output "dataform_repository_id" {
  value = google_dataform_repository.repo.id
}

output "bronze_dataset_id" {
  value = google_bigquery_dataset.bronze.dataset_id
}

output "silver_dataset_id" {
  value = google_bigquery_dataset.silver.dataset_id
}
