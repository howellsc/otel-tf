resource "google_compute_instance" "ubuntu_vm" {
  count = 5

  name         = "otel-spring-boot-${count.index}"
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

  metadata_startup_script = file("${path.module}/scripts/startup-otel-spring-boot.sh")

  tags = ["otel-spring-boot", "ssh"]
}
