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

output "aop_ca_cert_pem" {
  description = "CA certificate PEM — paste into cloudflare-origin-ca ConfigMap"
  value       = tls_self_signed_cert.aop_ca.cert_pem
}

output "aop_leaf_expiry" {
  description = "Leaf certificate expiry (plan rotation before this date)"
  value       = tls_locally_signed_cert.aop_leaf.validity_end_time
}

output "aop_ca_expiry" {
  description = "CA certificate expiry"
  value       = tls_self_signed_cert.aop_ca.validity_end_time
}
