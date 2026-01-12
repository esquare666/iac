include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../../../modules/dns"
}

locals {
  # Use inferred values from root include
  region      = include.root.locals.inferred_region
  environment = include.root.locals.inferred_environment

  # Get the folder name and construct DNS zone from it
  # Folder name: nz3es-example-com -> DNS: nz3es.example.com.
  folder_name = basename(get_terragrunt_dir())
  dns_name    = "${replace(local.folder_name, "-", ".")}."
}

inputs = {
  project_id  = include.root.locals.project_id
  zone_name   = format("%s-%s-zone", local.environment, local.folder_name)
  dns_name    = local.dns_name
  description = format("Public DNS zone %s for %s environment", local.dns_name, local.environment)
  visibility  = "public"

  labels = {
    environment = local.environment
    managed_by  = "terraform"
    region      = local.region
    zone_type   = "public"
  }

  recordsets = [
    # Example A record for stg subdomain
    {
      name    = "stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.10"]
    },
    # Example A record for app
    {
      name    = "app.stg"
      type    = "A"
      ttl     = 300
      records = ["10.1.0.20"]
    },
    # Example CNAME record
    {
      name    = "www.stg"
      type    = "CNAME"
      ttl     = 300
      records = ["app.stg.nz3es.example.com."]
    }
  ]
}
