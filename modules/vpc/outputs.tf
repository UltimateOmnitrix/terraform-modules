output "network_name" { value = google_compute_network.vpc.name }
output "subnet_name" { value = google_compute_subnetwork.privateSubnet.name }
output "pods_range_name" { value = "pods" }
output "services_range_name" { value = "services" }
