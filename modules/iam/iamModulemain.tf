# -----------------------------------------------------------------------------
# File: main.tf
#
# Purpose:
# This Terraform file provisions the IAM components required to enable
# Workload Identity Federation (WIF) between GitHub Actions and Google Cloud
# Platform (GCP). It allows CI/CD pipelines to authenticate securely using
# OpenID Connect (OIDC) without relying on long-lived service account keys.
#
# What this file does:
# - Creates a Workload Identity Pool for external identities
# - Registers GitHub Actions as an OIDC identity provider
# - Restricts access to a specific GitHub repository
# - Creates a service account for automation for the Github actions
# - Grants impersonation permissions via WIF
# - Assigns project-level IAM roles to the service account

# Usage:
# This file is consumed as part of a reusable Terraform IAM module and is
# executed when called by env/prod/main.tf 
# -----------------------------------------------------------------------------




# Creates a Workload Identity Pool to represent external identities
# (GitHub Actions) that are allowed to authenticate to Google Cloud.
resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
}


# Configures GitHub Actions as an OpenID Connect (OIDC) provider
# within the Workload Identity Pool.
resource "google_iam_workload_identity_pool_provider" "github" {
  # FIX: Use the correct argument name
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

# -----------------------------------------------------------------------------
# Creates a service account used by CI/CD pipelines after
# successful Workload Identity Federation authentication.
# -----------------------------------------------------------------------------
resource "google_service_account" "platform_sa" {
  account_id   = "platform-sa"
  display_name = "Platform Automation Service Account"
}

# -----------------------------------------------------------------------------
# Grants GitHub Actions permission to impersonate the service account
# using Workload Identity Federation (no static keys).
# -----------------------------------------------------------------------------
resource "google_service_account_iam_member" "wif_sa_binding" {
  service_account_id = google_service_account.platform_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/attribute.repository/${var.github_repo}"
}

# -----------------------------------------------------------------------------
# Grants project-level permissions to the automation service account.
# This enables CI/CD pipelines to manage GCP resources.
# -----------------------------------------------------------------------------
resource "google_project_iam_member" "project_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.platform_sa.email}"
}
