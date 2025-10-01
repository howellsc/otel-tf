provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable necessary APIs if not already
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}
resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}
resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_compute_network" "otel_net" {
  name                    = "otel-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "otel_fw" {
  name    = "otel-collector-fw"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["4317", "4318", "8889"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_ssh" {
  name    = "otel-ssh"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

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

  metadata_startup_script = file("startup.sh")

  tags = ["otel-collector"]
}

# Cloud Router
resource "google_compute_router" "otel_nat_router" {
  name    = "otel-nat-router"
  region  = var.region
  network = google_compute_network.otel_net.name
}

# Cloud NAT
resource "google_compute_router_nat" "otel_cloud_nat" {
  name                               = "otel-cloud-nat"
  router                             = google_compute_router.otel_nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
