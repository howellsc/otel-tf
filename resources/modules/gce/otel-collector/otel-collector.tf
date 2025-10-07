resource "google_compute_instance_template" "otel_collector_template" {

  name         = "otel-collector"
  machine_type = var.machine_type
  region       = var.region

  disk {
    source_image = var.machine_image
    disk_size_gb = var.disk_size_gb
  }

  network_interface {
    network = var.vpc_id
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

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_instance_group_manager.otel_collector_mig.instance_group
  }

  health_checks = [google_compute_region_health_check.otel_collector_health_check.id]

  port_name = "http" # Refer to the named port in the MIG (usually "http" or "https")

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
    port_name    = "health-check"
    request_path = "/"
  }
}
