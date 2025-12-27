# The container for GitHub identities in your GCP Project
resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions-pool"
}

# The OIDC Provider (The Handshake)
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc { issuer_uri = "https://token.actions.githubusercontent.com" }
}

# The Service Account GitHub will impersonate
resource "google_service_account" "platform_sa" {
  account_id   = "platform-automation-sa"
  display_name = "SA for Platform CI/CD"
}

# Binding the Monorepo to the Service Account
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.platform_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/UltimateOmnitrix/platform-monorepo"
}

# Admin rights for the automation account
resource "google_project_iam_member" "admin" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.platform_sa.email}"
}
