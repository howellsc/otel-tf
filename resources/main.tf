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

module "vcp" {
  source = "./modules/network"

  region = var.region
}

module "sa" {
  source = "./modules/sa"

  project_id = var.project_id
}

module "prometheus_gce" {
  source = "./modules/gce/prometheus"

  zone          = var.zone
  machine_image = var.machine_image
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  vpc_subnet_id = module.vcp.vpc_subnet
  vm_sa_email   = module.sa.vm_sa_email
}

module "grafana_gce" {
  source = "./modules/gce/grafana"

  zone          = var.zone
  machine_image = var.machine_image
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  vpc_subnet_id = module.vcp.vpc_subnet
  vm_sa_email   = module.sa.vm_sa_email
}

module "otel_spring_boot_gce" {
  source = "./modules/gce/otel-spring-boot"

  zone          = var.zone
  machine_image = var.podman_machine_image
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  vpc_subnet_id = module.vcp.vpc_subnet
  vm_sa_email   = module.sa.vm_sa_email
}

module "tempo_gce" {
  source = "./modules/gce/tempo"

  zone          = var.zone
  machine_image = var.machine_image
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  vpc_subnet_id = module.vcp.vpc_subnet
  vm_sa_email   = module.sa.vm_sa_email
}

module "otel_collector_gce" {
  source = "./modules/gce/otel-collector"

  region        = var.region
  zone          = var.zone
  machine_image = var.machine_image
  machine_type  = var.machine_type
  disk_size_gb  = var.disk_size_gb
  vpc_id        = module.vcp.vpc_id
  vpc_subnet_id = module.vcp.vpc_subnet
  vm_sa_email   = module.sa.vm_sa_email
}
