resource "google_compute_instance" "grafana" {
  name         = "grafana"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.machine_image
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

  metadata_startup_script = file("startup-grafana.sh")

  tags = ["grafana", "ssh"]
}
