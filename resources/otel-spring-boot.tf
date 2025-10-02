resource "google_compute_instance" "ubuntu_vm" {
  name         = "otel-spring-boot"
  machine_type = var.machine_type
  zone         = var.zone

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

  metadata_startup_script = file("startup-otel-spring-boot.sh")

  tags = ["otel-spring-boot", "ssh"]
}
