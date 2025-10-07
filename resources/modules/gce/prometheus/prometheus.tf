resource "google_compute_instance" "prometheus" {
  name         = "prometheus"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.machine_image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = var.vpc_subnet_id
  }

  service_account {
    email  = var.vm_sa_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("startup-prometheus.sh")

  tags = ["prometheus", "ssh"]
}
