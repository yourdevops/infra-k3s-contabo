# output "tunnel_id" {
#   description = "Cloudflare Tunnel ID"
#   value       = cloudflare_zero_trust_tunnel_cloudflared.k3s.id
# }

# output "tunnel_token" {
#   description = "Tunnel token for cloudflared — add to Ansible vault as vault_cloudflared_tunnel_token"
#   value       = cloudflare_zero_trust_tunnel_cloudflared.k3s.tunnel_token
#   sensitive   = true
# }
