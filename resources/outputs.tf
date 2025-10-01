output "otel_collector_external_ip" {
  value       = google_compute_instance.otel_collector.network_interface[0].access_config[0].nat_ip
  description = "External IP address for OTEL collector (so your apps can push metrics/traces to it)"
}
