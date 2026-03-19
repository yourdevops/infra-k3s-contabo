output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = cloudflare_zone.this.id
}

output "zone_status" {
  description = "Cloudflare Zone status"
  value       = cloudflare_zone.this.status
}

output "zone_name_servers" {
  description = "Cloudflare-assigned nameservers"
  value       = cloudflare_zone.this.name_servers
}

output "tunnel_id" {
  description = "Cloudflare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.id
}

output "tunnel_status" {
  description = "Cloudflare Tunnel status"
  value       = cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.status
}

output "tunnel_cname" {
  description = "Tunnel CNAME target"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.id}.cfargotunnel.com"
}

output "wildcard_dns_record_id" {
  description = "Wildcard DNS record ID"
  value       = cloudflare_dns_record.wildcard_tunnel.id
}
