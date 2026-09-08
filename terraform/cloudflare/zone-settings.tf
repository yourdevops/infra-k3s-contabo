# Edge TLS settings for the zone. These settings exist on every zone, so
# Terraform takes them over on first apply without an import.
#
# The workspace API token needs "Zone Settings: Edit" on this zone.

# Origin certificate must be valid and trusted (Let's Encrypt wildcard).
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "ssl"
  value      = "strict"
}

# Redirect http:// to https:// at the edge; the in-cluster tls-redirect
# HTTPRoute stays as a fallback for traffic that bypasses this setting.
resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "always_use_https"
  value      = "on"
}
