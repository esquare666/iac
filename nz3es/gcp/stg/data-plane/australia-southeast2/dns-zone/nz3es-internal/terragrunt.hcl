include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../../../modules/dns"
}

dependency "vpc" {
  config_path = "../../network"

  # Mock outputs for planning phase when VPC hasn't been applied yet
  mock_outputs = {
    network_self_link = "https://www.googleapis.com/compute/v1/projects/mock-project/global/networks/mock-network"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  # Use inferred values from root include
  region      = include.root.locals.inferred_region
  environment = include.root.locals.inferred_environment

  # Get the folder name and construct DNS zone from it
  # Folder name: nz3es-internal -> DNS: nz3es.internal.
  folder_name = basename(get_terragrunt_dir())
  dns_name    = "${replace(local.folder_name, "-", ".")}."
}

inputs = {
  project_id  = include.root.locals.project_id
  zone_name   = format("%s-%s-zone", local.environment, local.folder_name)
  dns_name    = local.dns_name
  description = format("Internal DNS zone %s for %s environment", local.dns_name, local.environment)
  visibility  = "private"

  # Private DNS zone requires VPC network association
  private_networks = [dependency.vpc.outputs.network_self_link]

  labels = {
    environment = local.environment
    managed_by  = "terraform"
    region      = local.region
    zone_type   = "internal"
  }

  recordsets = [
    # Example internal A records
    {
      name    = "db.stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.100"]
    },
    {
      name    = "cache.stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.101"]
    },
    {
      name    = "api.stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.102"]
    },
    {
      name    = "api1.stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.103"]
    }
  ]
}
