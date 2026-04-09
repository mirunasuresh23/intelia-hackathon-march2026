variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "miruna-sandpit"
}

variable "region" {
  description = "The region for datasets and resources"
  type        = string
  default     = "US"
}

variable "bucket_name" {
  description = "The GCS bucket name for bronze data"
  type        = string
}

variable "git_repo_url" {
  description = "The URL of the Git repository for Dataform"
  type        = string
}

variable "source_bucket_name" {
  description = "The GCS bucket name for source code"
  type        = string
}
