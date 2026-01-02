resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  # FIX 1: Rename 'provider_id' to the correct argument name
  workload_identity_pool_provider_id = "github-provider"

  workload_identity_pool_id = google_iam_workload_identity_pool.main.workload_identity_pool_id
  display_name              = "GitHub Provider"
  description               = "OIDC Provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
  }

  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
