# Root Terragrunt configuration - common settings for all environments
# Edit the `bucket` value below to the GCS bucket you will use for Terraform state.
# Set the environment variable GOOGLE_APPLICATION_CREDENTIALS with your service account JSON.
#     GCP_PROJECT: iac-01
#     GCP_REGION: australia-southeast2

locals {
  project_id = get_env("GCP_PROJECT", "default-project")
  region     = get_env("GCP_REGION", "default-region")

  # Absolute path of the Terragrunt working directory that included this file
  terragrunt_working_dir = get_terragrunt_dir()

  # Normalize separators and split into components
  _path_components = split("/", replace(local.terragrunt_working_dir, "\\", "/"))

  # Reverse for easy access to the last segments
  _reversed_components = reverse(local._path_components)

  # Allowed environments and allowed regions (explicit list for stricter checks)
  # MUST be defined first before using in other locals
  allowed_environments = ["dev", "stg", "uat", "prd", "qa"]
  allowed_regions = [
    "australia-southeast2",
    "australia-southeast1"
  ]

  # Inferred values - dynamically finds region and environment from path
  # This approach scales to any folder depth (network, dns-zone, sql, cache, etc.)
  # Examples:
  #   .../stg/data-plane/australia-southeast2/network
  #   .../stg/data-plane/australia-southeast2/dns-zone/nz3es-example-com
  #   .../stg/data-plane/australia-southeast2/sql/cloudsql-instance
  #   .../prd/australia-southeast2/cache/redis

  # Find region: search through ALL path components for a match in allowed_regions
  _region_search = [for comp in local._path_components : comp if contains(local.allowed_regions, comp)]
  inferred_region = length(local._region_search) > 0 ? local._region_search[0] : "unknown-region"

  # Find environment: search through ALL path components for a match in allowed_environments
  _env_search = [for comp in local._path_components : comp if contains(local.allowed_environments, comp)]
  inferred_environment = length(local._env_search) > 0 ? local._env_search[0] : "unknown-env"

  # Validation flags
  inferred_env_valid    = contains(local.allowed_environments, local.inferred_environment)
  inferred_region_valid = contains(local.allowed_regions, local.inferred_region)

  folder_layout_valid = local.inferred_env_valid && local.inferred_region_valid
}
# Remote state configuration (GCS backend for remote state)
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite" # or "skip", "error"
  }
  config = {
    bucket = "nz3es-tf-state-iac"
    prefix = "tfstate/${path_relative_to_include()}"
  }
}

# Generate a small Terraform validation file in each working dir. This writes
# a boolean variable whose default is the evaluated folder_layout_valid value.
# Terraform's variable validation will fail during `plan`/`validate` if the
# folder layout is invalid.

generate "folder_validation" {
  path      = "terragrunt_folder_validation.tf"
  if_exists = "overwrite"
  contents  = <<EOF
variable "terragrunt_folder_validation_dummy" {
  type    = bool
  default = ${local.folder_layout_valid}

  validation {
    condition     = var.terragrunt_folder_validation_dummy == true
    error_message = "Invalid folder layout: inferred environment='${local.inferred_environment}', inferred region='${local.inferred_region}'. Allowed environments: ${join(", ", local.allowed_environments)}. Allowed regions: ${join(", ", local.allowed_regions)}"
  }
}
EOF
}

# Generate a provider.tf in each module folder with provider config derived from env
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = "${local.project_id}"
  region  = "${local.region}"
}

EOF
}
