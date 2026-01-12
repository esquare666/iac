output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "subnet_self_link" {
  value = google_compute_subnetwork.subnet.self_link
}

