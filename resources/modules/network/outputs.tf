output "vpc_id" {
  value = google_compute_network.otel_net.id
}

output "vpc_subnet" {
  value = google_compute_subnetwork.otel_subnet.id
}
