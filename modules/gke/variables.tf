variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy the cluster and nodes in"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet for the cluster"
  type        = string
}

variable "pods_range_name" {
  description = "The name of the secondary range for pods"
  type        = string
}

variable "services_range_name" {
  description = "The name of the secondary range for services"
  type        = string
}
