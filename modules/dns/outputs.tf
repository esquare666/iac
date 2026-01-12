output "zone_name" {
  description = "The name of the DNS zone"
  value       = google_dns_managed_zone.dns_zone.name
}

output "zone_id" {
  description = "The ID of the DNS zone"
  value       = google_dns_managed_zone.dns_zone.id
}

output "dns_name" {
  description = "The DNS name of the zone"
  value       = google_dns_managed_zone.dns_zone.dns_name
}

output "name_servers" {
  description = "The name servers for the DNS zone"
  value       = google_dns_managed_zone.dns_zone.name_servers
}

output "recordsets" {
  description = "The DNS recordsets created"
  value = {
    for k, v in google_dns_record_set.records : k => {
      name    = v.name
      type    = v.type
      ttl     = v.ttl
      rrdatas = v.rrdatas
    }
  }
}
