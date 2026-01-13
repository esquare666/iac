# Terragrunt Commands Reference

This document contains the commands used during setup and troubleshooting of the GCP infrastructure.

## Testing and Planning

### Run plan for all modules in an environment
```bash
cd nz3es/gcp/prd/data-plane/australia-southeast2
terragrunt run plan --all
```

### Run plan for specific module
```bash
# VPC only
cd nz3es/gcp/prd/data-plane/australia-southeast2/network
terragrunt plan

# Specific DNS zone
cd nz3es/gcp/prd/data-plane/australia-southeast2/dns-zone/nz3es-internal
terragrunt plan
```

## Troubleshooting Commands

### Release a stuck state lock
```bash
cd nz3es/gcp/prd/data-plane/australia-southeast2/network
terragrunt force-unlock -force <LOCK_ID>

# Example from troubleshooting session:
terragrunt force-unlock -force 1768252313229707
```

### Debug mode with verbose logging
```bash
terragrunt plan --terragrunt-log-level debug
```

### Filter plan output for summary
```bash
terragrunt run plan --all 2>&1 | grep -A 3 "Run Summary\|Plan:\|Error:\|inferred"
```

### View last 50 lines of plan output
```bash
terragrunt run plan --all 2>&1 | tail -50
```

### View last 100 lines of plan output
```bash
terragrunt run plan --all 2>&1 | tail -100
```

## Apply and Destroy

### Apply all modules
```bash
cd nz3es/gcp/prd/data-plane/australia-southeast2
terragrunt run apply --all
```

### Apply specific module
```bash
cd nz3es/gcp/prd/data-plane/australia-southeast2/network
terragrunt apply
```

### Destroy all resources
```bash
cd nz3es/gcp/prd/data-plane/australia-southeast2
terragrunt run destroy --all
```

## Common Issues and Solutions

### Issue: State lock error
**Error message:**
```
Error: Error acquiring the state lock
Lock ID: 1768252313229707
```

**Solution:**
```bash
cd network
terragrunt force-unlock -force 1768252313229707
```

### Issue: Invalid folder layout / region inference error
**Error message:**
```
Invalid folder layout: inferred environment='prd', inferred region='nz3es-example-com'
```

**Solution:** This was fixed in root.hcl by adding a third region candidate to properly handle the dns-zone folder structure.

### Issue: Dependency outputs not available during plan
**Error message:**
```
./network/terragrunt.hcl is a dependency of ./dns-zone/nz3es-internal/terragrunt.hcl but detected no outputs.
```

**Solution:** Added mock_outputs to the dependency block in private DNS zone configurations.

## Environment Variables

Make sure these are set before running terragrunt:
```bash
export GCP_PROJECT=iac-01
export GCP_REGION=australia-southeast2
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/nz3es-automation-sa-key.json
```

## Verification Commands

### Check terragrunt version
```bash
terragrunt --version
```

### Validate terragrunt configuration
```bash
terragrunt validate
```

### Show the terraform plan output
```bash
terragrunt show
```

### List all terragrunt modules
```bash
terragrunt run-all --help
```

## Scalable Folder Structure

The root.hcl automatically infers environment and region from ANY folder depth. You can add new service types without modifying root.hcl:

### Examples of supported folder structures:
```bash
# Network
nz3es/gcp/prd/data-plane/australia-southeast2/network/

# DNS zones
nz3es/gcp/prd/data-plane/australia-southeast2/dns-zone/nz3es-example-com/
nz3es/gcp/prd/data-plane/australia-southeast2/dns-zone/nz3es-internal/

# Future services (no root.hcl changes needed):
nz3es/gcp/prd/data-plane/australia-southeast2/sql/cloudsql-primary/
nz3es/gcp/prd/data-plane/australia-southeast2/cache/redis-main/
nz3es/gcp/prd/data-plane/australia-southeast2/gke/cluster-01/
nz3es/gcp/prd/data-plane/australia-southeast2/storage/gcs-buckets/
```

All paths will correctly infer:
- `environment = "prd"`
- `region = "australia-southeast2"`
