resource "google_compute_instance" "otel_collector" {
  name         = "otel-collector"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-9"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = google_compute_network.otel_net.name
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("startup-otel-collector.sh")

  tags = ["otel-collector", "ssh"]
}