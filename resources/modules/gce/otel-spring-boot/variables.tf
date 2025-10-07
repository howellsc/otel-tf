variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "machine_type" {
  description = "GCE machine types"
  type        = string
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
}

variable "machine_image" {
  description = "GCE machine image to use"
}

variable "vpc_subnet_id" {
  description = "VPC Subnet the GCE image is to use"
  type = string
}

variable "vm_sa_email" {
  description = "SA Email for the GCE"
  type        = string
}
