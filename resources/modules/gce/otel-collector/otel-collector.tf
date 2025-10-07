resource "google_compute_instance_template" "otel_collector_template" {

  name         = "otel-collector"
  machine_type = var.machine_type
  region       = var.region

  disk {
    source_image = var.machine_image
    disk_size_gb = var.disk_size_gb
  }

  network_interface {
    subnetwork = var.vpc_subnet_id
  }

  shielded_instance_config {
    enable_secure_boot = true
  }

  labels = {
    "type"    = "otel-collector"
    "purpose" = "metric-collecection"
  }

  service_account {
    email  = var.vm_sa_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = file("${path.module}/startup-otel-collector.sh")

  tags = ["otel-collector", "ssh"]
}

resource "google_compute_region_instance_group_manager" "otel_collector_mig" {
  name = "otel-collector-mig"

  region             = var.region
  base_instance_name = "otel-collector"
  version {
    instance_template = google_compute_instance_template.otel_collector_template.id
  }
  target_size = 2 # Number of backend instances

  named_port {
    name = "http"
    port = 4318
  }

  named_port {
    name = "health-check"
    port = 13133
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.otel_collector_health_check.id
    initial_delay_sec = 600
  }

  lifecycle {
    replace_triggered_by = [google_compute_instance_template.otel_collector_template]
  }

  depends_on = [google_compute_instance_template.otel_collector_template]
}

resource "google_compute_region_backend_service" "otel_collector_backend_service" {
  name     = "otel-collector"
  protocol = "HTTP"

  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_instance_group_manager.otel_collector_mig.instance_group
  }

  health_checks = [google_compute_region_health_check.otel_collector_health_check.id]

  port_name = "health-check" # Refer to the named port in the MIG (usually "http" or "https")

  depends_on = [
    google_compute_region_instance_group_manager.otel_collector_mig,
    google_compute_region_health_check.otel_collector_health_check
  ]
}

resource "google_compute_region_health_check" "otel_collector_health_check" {
  name                = "otel-collector-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  region              = var.region

  http_health_check {
    port = 13133
    # port_name    = "health-check"
    # port_specification = "USE_NAMED_PORT"
    request_path = "/"
  }
}

resource "google_compute_subnetwork" "otel_collector_proxy_only" {
  name          = "otel-collector-proxy-subnet"
  ip_cidr_range = "10.129.0.0/23" # must be in your VPC range
  region        = var.region
  network       = var.vpc_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_region_url_map" "otel_collector_url_map" {
  name            = "otel-collector-url-map"
  default_service = google_compute_region_backend_service.otel_collector_backend_service.self_link
  region          = var.region

  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_region_backend_service.otel_collector_backend_service.self_link
  }
}

resource "google_compute_region_target_http_proxy" "otel_collector_proxy" {
  name    = "otel-collector-http-proxy"
  url_map = google_compute_region_url_map.otel_collector_url_map.self_link
  region  = var.region
}

resource "google_compute_forwarding_rule" "otel_collector_forwarding_rule" {
  name                  = "otel-collector-http-forwarding-rule"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.otel_collector_proxy.self_link
  network               = var.vpc_id
  subnetwork            = var.vpc_subnet_id
  ip_protocol           = "TCP"
  region                = var.region
  ip_address            = google_compute_address.otel_collector_ip.self_link

  depends_on = [
    google_compute_subnetwork.otel_collector_proxy_only
  ]
}

resource "google_compute_address" "otel_collector_ip" {
  name         = "otel-collector-internal-ip"
  subnetwork   = var.vpc_subnet_id # The subnetwork where clients will connect
  region       = var.region
  network_tier = "PREMIUM"
  address_type = "INTERNAL" # <--- Crucial: Ensure it is an internal IP
}
