# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
}

# Configure the OIDC Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create the Automation Service Account
resource "google_service_account" "platform_sa" {
  account_id   = "platform-automation-sa"
  display_name = "SA for Platform CI/CD"
}

# Bind the GitHub Repo to the Service Account (The Handshake)
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.platform_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/UltimateOmnitrix/platform-monorepo"
}

# Grant Project Owner permissions to the SA
resource "google_project_iam_member" "admin" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.platform_sa.email}"
}
