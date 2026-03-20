data "terraform_remote_state" "contabo" {
  backend = "remote"

  config = {
    organization = "yourdevops"
    workspaces = {
      name = "contabo"
    }
  }
}

resource "cloudflare_zone" "this" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain
}

# Tunnel kept alive for future WARP-only private services
resource "cloudflare_zero_trust_tunnel_cloudflared" "k3s_contabo" {
  account_id = var.cloudflare_account_id
  name       = "k3s-contabo"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "k3s_contabo" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.id
  config = {
    ingress = [
      {
        service = "http_status:404"
      },
    ]
  }
}

# SSH access — not proxied
resource "cloudflare_dns_record" "s01" {
  zone_id = cloudflare_zone.this.id
  name    = "s01.${var.domain}"
  type    = "A"
  content = data.terraform_remote_state.contabo.outputs.instance_s01.ip_config[0].v4[0].ip
  proxied = false
  ttl     = 1
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.this.id
  setting_id = "ssl"
  value      = "full_strict"
}
