resource "google_compute_network" "otel_net" {
  name                    = "otel-network"
  auto_create_subnetworks = true
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

resource "google_compute_firewall" "otel_fw" {
  name    = "otel-collector-fw"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["4317", "4318", "8889", "8888"]
  }

  target_tags = ["otel-collector"]

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

resource "google_compute_firewall" "prometheus_http" {
  name    = "prometheus-http"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  target_tags = ["prometheus"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_collector_prometheus" {
  name    = "otel-collector-prometheus"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  target_tags = ["otel-collector"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_collector_tempo" {
  name    = "otel-collector-tempo"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["4317"]
  }

  target_tags = ["otel-tempo"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "prometheus_otel_collector" {
  name    = "prometheus-otel-collector"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8889"]
  }

  target_tags = ["prometheus"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "prometheus_tempo" {
  name    = "prometheus-tempo"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3100"]
  }

  target_tags = ["prometheus"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_spring_boot_otel_collector" {
  name    = "otel-spring-boot-otel-collector"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["4318"]
  }

  target_tags = ["otel-spring-boot"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "otel_spring_boot_http" {
  name    = "otel-spring-boot-http"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  target_tags = ["otel-spring-boot"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "grafana_http" {
  name    = "grafana-http"
  network = google_compute_network.otel_net.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "9090"]
  }

  target_tags = ["grafana"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "grafana_tempo" {
  name    = "grafana-tempo"
  network = google_compute_network.otel_net.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3100"]
  }

  target_tags = ["grafana"]

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tempo" {
  name    = "tempo"
  network = google_compute_network.otel_net.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["4318", "4317", "3200", "3100"]
  }

  target_tags = ["tempo"]

  source_ranges = ["0.0.0.0/0"]
}
