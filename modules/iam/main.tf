resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider_id               = "github-provider"
  workload_identity_pool_id = google_iam_workload_identity_pool.main.workload_identity_pool_id
  display_name              = "GitHub Provider"
  description               = "OIDC Provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
  }

  # THIS LINE USES THE VARIABLE
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Output the provider name so we can use it later
output "wif_provider_name" {
  value = google_iam_workload_identity_pool_provider.github.name
}
