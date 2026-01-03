output "wif_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "The full identifier for the WIF provider"
}

output "service_account_email" {
  value       = google_service_account.platform_sa.email
  description = "The email of the automation service account"
}
