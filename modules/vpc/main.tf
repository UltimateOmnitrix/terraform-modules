

# 1. The Custom VPC   
# Choose the auto_create_subnetworks to false to create a custom VPC 
resource "google_compute_network" "vpc" {
  name                    = "platform-vpc-prod"
  project                 = var.project_id
  auto_create_subnetworks = false
}

## Primary subnets are for stable VM IPs; secondary ranges are required for the dynamic and virtual nature of Pods and Services to ensure scalability, predictable routing, and zero IP conflicts.
# 2. The Subnet with Secondary Ranges (Task 2.1)
resource "google_compute_subnetwork" "privateSubnet" {
  name    = "gke-private-subnet"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
  ## 10.0.0.0/20 is the default range for GKE NODES range of 10.0.0.0 – 10.0.15.255
  ## Reason why the GKE is using this primary subnet range is nodes IPs are statically bound 
  ## to VM NICs, which mean Primary IP's(privateSubnet) are ment for VM's
  ## These primary range are too slow & restricive, Not designed for massive allocation like to pods
  ip_cidr_range = "10.0.0.0/20"


  # Secondary range for Pods (/14)
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.48.0.0/14"
    ## Pods have this secondary cause they are dynamically allocated
    ## As pods are emphimerial and short-lived, using the secondary range gets allocattes 
    ## the IP's faster than the primary(privateSubnet)
  }



  # Secondary range for Services (/20)
  ## The Service in here is one fixed internal IP address that points to a group of Pods. 
  ## as pods Die, restart, if apps talk directly to Pod Ip's, your app would break, 
  ## you would have zero-downtime.. 
  ## SO having Services it has one stable IP(clusterIP), internally forwards traffic to healty pods
  ## Service can load-balances automatically... And They must not confilt with Pod or Node ip's 

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.52.0.0/20"
    ## Services have this secondary cause they are dynamically allocated
    ## Seconday helps in a way to get ip's allocated faster
  }

  # reason why private_ip_google_access is true is to allow GKE nodes to reach Google APIs 
  # privately without using the internet (mean without using public IP's)  
  private_ip_google_access = true
}

# 3. Cloud Router (Task 2.2)
## Cloud ROuter & Cloud NAT provivde otubound internet access for the private nodes
resource "google_compute_router" "router" {
  # router manages the routes, tells google network where traffic shoud go
  name    = "platform-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# 4. Cloud NAT (Task 2.2)
resource "google_compute_router_nat" "nat" {
  # NAT is virtual router that proovides outbound access for private resouce 
  # transaltes private ip's to public ip's 
  name                               = "platform-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"                     # let GCP manage public NAT IP's automatically 
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" # allows every private IP in the VPC to use Cloud NAT for outbound
}
