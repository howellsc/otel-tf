resource "google_compute_network" "otel_net" {
  name                    = "otel-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "otel_subnet" {
  name          = "otel-subnet"
  region        = var.region
  ip_cidr_range = "10.132.0.0/20"

  private_ip_google_access = true

  network = google_compute_network.otel_net.id

  lifecycle {
    create_before_destroy = false
    replace_triggered_by  = [google_compute_network.otel_net]
  }
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
