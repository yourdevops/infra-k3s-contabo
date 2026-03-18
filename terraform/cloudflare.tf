resource "cloudflare_zone" "this" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain
}

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
        hostname = "*.${var.domain}"
        service  = "http://kong-kong-proxy.kong.svc.cluster.local:80"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

resource "cloudflare_dns_record" "wildcard_tunnel" {
  zone_id = cloudflare_zone.this.id
  name    = "*.${var.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
