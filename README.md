# GCP Infrastructure as Code (Terragrunt)

Infrastructure as Code for GCP using Terragrunt and Terraform modules.

## Project Structure

```text
iac/
├── root.hcl                      # Root Terragrunt configuration
├── modules/                      # Reusable Terraform modules
│   ├── vpc/                      # VPC network module
│   └── dns/                      # Cloud DNS module
└── nz3es/gcp/                    # Organization/Project structure
    ├── stg/                      # Staging environment
    │   └── data-plane/
    │       └── australia-southeast2/
    │           ├── network/      # VPC configuration
    │           └── dns-zone/     # DNS zones
    │               ├── nz3es-example-com/    # Public DNS zone
    │               └── nz3es-internal/       # Private DNS zone
    └── prd/                      # Production environment
        └── data-plane/
            └── australia-southeast2/
                ├── network/
                └── dns-zone/
                    ├── nz3es-example-com/
                    └── nz3es-internal/
```

## Module Features

### VPC Module (`modules/vpc`)

- Creates VPC network
- Configurable subnet with CIDR range
- Outputs network self-link for DNS integration

### DNS Module (`modules/dns`)

- Supports both public and private DNS zones
- DNS zone name derived from folder name (e.g., `nz3es-example-com` → `nz3es.example.com.`)
- Short record names (automatically appends zone suffix)
- Recordsets as array with intuitive structure:

  ```hcl
  recordsets = [
    {
      name    = "app"              # Short name (auto-appends zone)
      type    = "A"
      ttl     = 300
      records = ["10.0.0.10"]
    }
  ]
  ```

## Prerequisites (Bootstrap)

### 1. Enable Required APIs

```bash
gcloud services enable cloudresourcemanager.googleapis.com --project=iac-01
gcloud services enable config.googleapis.com --project=iac-01
gcloud services enable cloudquotas.googleapis.com --project=iac-01
gcloud services enable dns.googleapis.com --project=iac-01
gcloud services enable compute.googleapis.com --project=iac-01
```

### 2. Create Terraform State Bucket

```bash
gcloud storage buckets create gs://nz3es-tf-state-iac \
    --location=australia-southeast2 \
    --project=iac-01

# Enable versioning
gcloud storage buckets update gs://nz3es-tf-state-iac --enable-versioning
```

### 3. Create Service Account

```bash
gcloud iam service-accounts create nz3es-automation-sa \
    --description="SA for automation" \
    --display-name="nz3es-automation-sa" \
    --project=iac-01
```

### 4. Create Service Account Key

```bash
gcloud iam service-accounts keys create nz3es-automation-sa-key.json \
    --iam-account=nz3es-automation-sa@iac-01.iam.gserviceaccount.com \
    --project=iac-01
```

### 5. Grant Required Roles

```bash
# Infrastructure Manager agent role
gcloud projects add-iam-policy-binding iac-01 \
    --member="serviceAccount:nz3es-automation-sa@iac-01.iam.gserviceaccount.com" \
    --role="roles/config.agent"

# Network admin
gcloud projects add-iam-policy-binding iac-01 \
    --member="serviceAccount:nz3es-automation-sa@iac-01.iam.gserviceaccount.com" \
    --role="roles/compute.networkAdmin"

# DNS admin
gcloud projects add-iam-policy-binding iac-01 \
    --member="serviceAccount:nz3es-automation-sa@iac-01.iam.gserviceaccount.com" \
    --role="roles/dns.admin"

# Storage admin (for state bucket)
gcloud projects add-iam-policy-binding iac-01 \
    --member="serviceAccount:nz3es-automation-sa@iac-01.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

**Additional roles as needed:**

```bash
--role="roles/compute.instanceAdmin.v1"
--role="roles/iam.serviceAccountUser"
--role="roles/container.admin"
--role="roles/bigquery.admin"
--role="roles/serviceusage.serviceUsageAdmin"
```

### 6. Set Environment Variables

```bash
export GCP_PROJECT=iac-01
export GCP_REGION=australia-southeast2
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/nz3es-automation-sa-key.json
```

## Usage

### Running Terragrunt

**Run all modules in an environment/region:**

```bash
cd nz3es/gcp/stg/data-plane/australia-southeast2

# Terragrunt v0.96.0+ uses the new syntax
terragrunt run plan --all
terragrunt run apply --all
```

**Run specific module:**

```bash
# VPC only
cd nz3es/gcp/stg/data-plane/australia-southeast2/network
terragrunt plan
terragrunt apply

# Specific DNS zone
cd nz3es/gcp/stg/data-plane/australia-southeast2/dns-zone/nz3es-internal
terragrunt plan
terragrunt apply
```

**Destroy resources:**

```bash
cd nz3es/gcp/stg/data-plane/australia-southeast2
terragrunt run destroy --all
```

### Creating New DNS Zones

To add a new DNS zone, simply create a folder with the DNS name using hyphens:

```bash
cd nz3es/gcp/stg/data-plane/australia-southeast2/dns-zone
mkdir my-domain-com  # Will create DNS zone: my.domain.com.
```

Then create a `terragrunt.hcl` file following the existing pattern.

## Configuration Details

### Root Configuration (`root.hcl`)

The root configuration:

- **Dynamically infers environment and region** from folder path by searching through all path components
- Supports any folder structure depth (network, dns-zone, sql, cache, etc.)
- No need to modify root.hcl when adding new service folders
- Validates folder structure against allowed environments and regions
- Generates provider configuration automatically
- Configures GCS backend for remote state

**Allowed Environments:** `dev`, `stg`, `uat`, `prd`, `qa`

**Allowed Regions:** `australia-southeast2`, `australia-southeast1`

**Scalable Design:** You can add any service folders (sql, cache, gke, etc.) at any depth without modifying root.hcl. The configuration automatically finds the environment and region from the path.

### DNS Record Configuration

The DNS module supports short record names that automatically append the zone suffix:

```hcl
recordsets = [
  {
    name    = "@"           # Zone apex (nz3es.example.com.)
    type    = "A"
    ttl     = 300
    records = ["10.0.0.10"]
  },
  {
    name    = "app"         # Becomes: app.nz3es.example.com.
    type    = "A"
    ttl     = 300
    records = ["10.0.0.20"]
  },
  {
    name    = "www"         # Becomes: www.nz3es.example.com.
    type    = "CNAME"
    ttl     = 300
    records = ["app.nz3es.example.com."]  # CNAME target (fully qualified)
  }
]
```

**Record Types Supported:** A, AAAA, CNAME, MX, TXT, NS, SRV, etc.

## Troubleshooting

### Common Issues

1. **"Invalid folder layout" error**
   - Ensure you're in the correct directory structure
   - Check environment and region names match allowed values

2. **"Module not found" error**
   - Verify relative paths in `source` parameter
   - Check that you're running from the correct directory

3. **VPC dependency errors in DNS**
   - Ensure VPC is deployed first
   - Check dependency path: `config_path = "../../network"`

4. **State locking issues**
   - Ensure only one terragrunt process runs at a time
   - Check GCS bucket permissions

### Debug Mode

Enable debug output:

```bash
terragrunt plan --terragrunt-log-level debug
```

## References

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Cloud DNS Documentation](https://cloud.google.com/dns/docs)
- [Infrastructure Manager](https://cloud.google.com/infrastructure-manager/docs)
