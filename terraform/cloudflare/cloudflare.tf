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

resource "cloudflare_dns_record" "s01" {
  zone_id = cloudflare_zone.this.id
  name    = "s01.${var.domain}"
  type    = "A"
  content = data.terraform_remote_state.contabo.outputs.instance_s01.ip_config[0].v4[0].ip
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "wildcard_tunnel" {
  zone_id = cloudflare_zone.this.id
  name    = "*.${var.domain}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k3s_contabo.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}
