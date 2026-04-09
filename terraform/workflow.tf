# workflow.tf

# 1. Zip the Cloud Function source code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/archive_gcs"
  output_path = "${path.module}/../functions/archive_gcs.zip"
}

# Create a dedicated bucket for source code
resource "google_storage_bucket" "source_bucket" {
  name          = var.source_bucket_name
  location      = var.region
  force_destroy = true
}

# 2. Upload the zip to the Source GCS Bucket
resource "google_storage_bucket_object" "function_zip" {
  name   = "functions/archive_gcs.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.function_zip.output_path
}

data "google_project" "project" {}

# Grant Cloud Functions service agent access to the source bucket
resource "google_storage_bucket_iam_member" "gcf_bucket_access" {
  bucket = google_storage_bucket.source_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${data.google_project.project.number}@gcf-admin-robot.iam.gserviceaccount.com"
}


# 3. Create the Cloud Function (Gen 2)
resource "google_cloudfunctions2_function" "archive_function" {
  name        = "archive-gcs-function"
  location    = "us-central1" # Standardized location
  description = "Archives processed bronze files"

  build_config {
    runtime     = "python311"
    entry_point = "archive_gcs_files"
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    available_memory = "256M"
    timeout_seconds  = 120
    # Allow the custom workflow SA to invoke it
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.artifactregistry,
    google_project_service.run,
    google_storage_bucket_iam_member.gcf_bucket_access
  ]
}

# 4. Create a Service Account for the Workflow
resource "google_service_account" "workflow_sa" {
  account_id   = "orchestration-workflow-sa"
  display_name = "Orchestration Workflow Service Account"
}

# Grant Workflow SA roles to trigger Dataform, invoke Cloud Run/Functions, and write logs
resource "google_project_iam_member" "workflow_dataform" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

resource "google_project_iam_member" "workflow_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Allow Workflow SA to trigger workflow executions (for the Scheduler to use it)
resource "google_project_iam_member" "workflow_executor" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# 5. Define the Cloud Workflow
resource "google_workflows_workflow" "orchestrator" {
  name            = "dataform-orchestrator"
  region          = "us-central1"
  description     = "Daily workflow to run Dataform and archive files"
  service_account = google_service_account.workflow_sa.id

  # Inject Terraform variables as ENV variables for the Workflow to read
  user_env_vars = {
    GCP_PROJECT_ID       = var.project_id
    GCP_LOCATION         = "us-central1"
    ARCHIVE_FUNCTION_URL = google_cloudfunctions2_function.archive_function.service_config[0].uri
  }

  source_contents = file("${path.module}/../workflow.yaml")

  depends_on = [
    google_project_iam_member.workflow_dataform,
    google_project_iam_member.workflow_invoker,
    google_project_service.dataform
  ]
}

# 6. Cloud Scheduler to trigger the Workflow daily
resource "google_cloud_scheduler_job" "daily_trigger" {
  name             = "daily-data-pipeline"
  region           = "us-central1"
  schedule         = "0 8 * * *" # Runs every day at 8:00 AM
  time_zone        = "Australia/Sydney"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/us-central1/workflows/${google_workflows_workflow.orchestrator.name}/executions"
    
    oauth_token {
      service_account_email = google_service_account.workflow_sa.email
    }
  }

  depends_on = [
    google_project_service.cloudscheduler
  ]
}
