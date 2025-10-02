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