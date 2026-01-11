include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/vpc"
}

locals {
  # Use inferred values from root include
  region      = include.root.locals.inferred_region
  environment = include.root.locals.inferred_environment
}

inputs = {
  project_id  = include.root.locals.project_id
  region      = local.region
  name        = format("%s-vpc-%s", local.environment, local.region)
  subnet_cidr = "10.1.0.0/24"
}
