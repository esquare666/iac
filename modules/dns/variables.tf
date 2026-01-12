variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone_name" {
  description = "Name of the DNS zone (must be unique within the project)"
  type        = string
}

variable "dns_name" {
  description = "The DNS name of this managed zone (must end with a period)"
  type        = string
}

variable "description" {
  description = "Description of the DNS zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "visibility" {
  description = "Visibility of the zone (public or private)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "Visibility must be either 'public' or 'private'."
  }
}

variable "private_networks" {
  description = "List of VPC network URLs for private DNS zones"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the DNS zone"
  type        = map(string)
  default     = {}
}

variable "recordsets" {
  description = "List of DNS recordsets to create"
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    records = list(string)
  }))
  default = []
}
