/**
 * GKE Cluster & Node Pool Module
 *
 * This Terraform configuration provisions a hardened, production-ready
 * Google Kubernetes Engine (GKE) cluster using VPC-native networking.
 *
 * Key characteristics:
 * - Runs inside a pre-existing custom VPC and private subnet
 * - Uses secondary IP ranges for Pods and ClusterIP Services (alias IPs)
 * - Deploys a private GKE cluster with no public IPs on worker nodes
 * - Control plane is Google-managed and communicates with nodes via a
 *   dedicated private CIDR block
 * - Default node pool is disabled in favor of a custom-managed node pool
 */

resource "google_container_cluster" "primary" {
  name     = "omnitrix-cluster"
  project  = var.project_id
  location = var.region

  # Task 2.3: Minimum version 1.34+ (Standard Channel)
  min_master_version = "1.34"

  # network is for the VPC and subnetwork is for the subnet
  network    = var.network_name
  subnetwork = var.subnet_name

  # Secondary Ranges for IP Aliasing as we are using VPC-native
  # First secondary is for the pods 
  # Second secondary is for the services which are fixed internal IP's 
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Hardening: Private Nodes
  private_cluster_config {
    # Worker node do Not get public IP address with enable_private_nodes is true, they have only PRivate IP's 
    enable_private_nodes = true

    # enable_private_endpoint is false it means only the AUTH IAM role can access the cluster the K8s API server
    ## this is for more information!!! if you mark it as True, then u can access only by VPN or bastion host (True max security)
    enable_private_endpoint = false

    # this defines private IP range reserved exclusively for the control pane to node communication in private cluster 
    # these ip are for api server, scheduler, controller manager, etcd, etc
    # the google managed control plane gets these ip's 
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # Task 2.3: Disable default node pool
  # when launching the GKE cluster, it needs to create a defualt node pool, 
  # or the cluster will not be created 
  # as soon as the cluster is created, we are removing the default node pool and passing an intial value 
  # as 1 as a temporary value 
  remove_default_node_pool = true
  initial_node_count       = 1

  # this protection to allow deletion of the cluster using tf destroy, CI/CD clean up
  deletion_protection = false
}



# Task 2.3: Custom Node Pool THis is actual node pool WE are attaching node pool the control plane
resource "google_container_node_pool" "primary_nodes" {
  name       = "main-pool"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 2 # 3 nodes requirement

  node_config {
    machine_type = "n2-standard-4" # N2-Standard-4 requirement 

    # this oauth_scopes is for the nodes to access google apis 
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
