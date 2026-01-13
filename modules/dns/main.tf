resource "google_dns_managed_zone" "dns_zone" {
  name        = var.zone_name
  dns_name    = var.dns_name
  description = var.description
  project     = var.project_id

  visibility = var.visibility

  dynamic "private_visibility_config" {
    for_each = var.visibility == "private" ? [1] : []
    content {
      dynamic "networks" {
        for_each = var.private_networks
        content {
          network_url = networks.value
        }
      }
    }
  }

  labels = var.labels
}

resource "google_dns_record_set" "records" {
  for_each = { for idx, record in var.recordsets : idx => record }

  # Auto-append zone name if not already present
  # If name is "@" or empty, use zone name directly
  # If name ends with ".", use as-is (fully qualified)
  # Otherwise, append ".{zone_name}"
  name = (
    each.value.name == "@" || each.value.name == "" ? var.dns_name :
    endswith(each.value.name, ".") ? each.value.name :
    "${each.value.name}.${var.dns_name}"
  )

  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = google_dns_managed_zone.dns_zone.name
  project      = var.project_id

  rrdatas = each.value.records
}
