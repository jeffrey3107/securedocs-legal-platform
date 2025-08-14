# main.tf - Simple SecureDocs Legal Platform Demo
# This single file contains all infrastructure needed for the demo

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
  default     = "us-central1"
}

# Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "storage.googleapis.com"
  ])
  service = each.key
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "securedocs-vpc"
  auto_create_subnetworks = false
  depends_on             = [google_project_service.apis]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "securedocs-subnet"
  ip_cidr_range = "10.1.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.2.0.0/16"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.3.0.0/20"
  }
}

# Firewall - Allow internal traffic
resource "google_compute_firewall" "internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  source_ranges = ["10.0.0.0/8"]
}

# Firewall - Allow web traffic
resource "google_compute_firewall" "web" {
  name    = "allow-web"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

# GKE Cluster
resource "google_container_cluster" "cluster" {
  name     = "securedocs-cluster"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  # Security settings
  private_cluster_config {
    enable_private_nodes   = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
}

# GKE Node Pool
resource "google_container_node_pool" "nodes" {
  name       = "main-pool"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-micro"  # Smaller machine type
    disk_size_gb = 20          # Smaller disk size
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    tags = ["web"]
  }
  
  autoscaling {
    min_node_count = 1
    max_node_count = 2         # Reduced max nodes
  }
}

# Cloud SQL Database
resource "google_sql_database_instance" "db" {
  name             = "securedocs-db"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Smallest for demo
    
    backup_configuration {
      enabled = true
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
  
  deletion_protection = false
  depends_on = [google_service_networking_connection.db_connection]
}

# Private IP for Cloud SQL
resource "google_compute_global_address" "db_ip" {
  name          = "db-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# VPC Peering for Cloud SQL
resource "google_service_networking_connection" "db_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.db_ip.name]
}

# Storage Bucket for Documents
resource "google_storage_bucket" "documents" {
  name     = "${var.project_id}-securedocs-demo"
  location = var.region
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# Load Balancer IP
resource "google_compute_global_address" "lb_ip" {
  name = "securedocs-lb-ip"
}

# Outputs for demo
output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.cluster.endpoint
  sensitive = true
}

output "database_name" {
  value = google_sql_database_instance.db.name
}

output "bucket_name" {
  value = google_storage_bucket.documents.name
}

output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}