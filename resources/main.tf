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

  target_tags = ["otel-collector"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "prometheus_http" {
  name    = "prometheus_http"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  target_tags = ["prometheus"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_ssh" {
  name    = "otel-ssh"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh"]

  source_ranges = ["0.0.0.0/0"]
}

# Create the service account
resource "google_service_account" "vm_sa" {
  project      = var.project_id
  account_id   = "vm-service-account"
  display_name = "VM Service Account"
}

resource "google_project_iam_member" "vm_sa_compute" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "vm_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
}

resource "google_project_iam_member" "vm_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm_sa.email}"
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

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("startup-otel-collector.sh")

  tags = ["otel-collector", "ssh"]
}

resource "google_compute_instance" "prometheus" {
  name         = "prometheus"
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

  metadata_startup_script = file("startup-prometheus.sh")

  tags = ["prometheus", "ssh"]
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
