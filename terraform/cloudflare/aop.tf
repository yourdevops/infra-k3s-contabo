# Cloudflare Authenticated Origin Pulls (mTLS)
#
# Envoy Gateway requires a client certificate from Cloudflare to prove
# traffic originates from our zone. Zone-level AOP with custom PKI:
# - CA cert  → K8s Secret (Envoy validates against it)
# - Leaf cert → Cloudflare (presents it to Envoy on every request)
#
# Rotation: taint tls_private_key.aop_leaf → apply → update K8s Secret
# Full CA rotation: taint tls_private_key.aop_ca → apply → update K8s Secret

# -----------------------------------------------------------------------------
# Private CA
# -----------------------------------------------------------------------------

resource "tls_private_key" "aop_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "aop_ca" {
  private_key_pem = tls_private_key.aop_ca.private_key_pem

  subject {
    common_name  = var.domain
    organization = "yourdevops"
  }

  validity_period_hours = 87600 # ~10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# -----------------------------------------------------------------------------
# Leaf certificate (presented by Cloudflare to Envoy)
# -----------------------------------------------------------------------------

resource "tls_private_key" "aop_leaf" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "aop_leaf" {
  private_key_pem = tls_private_key.aop_leaf.private_key_pem

  subject {
    common_name  = "*.${var.domain}"
    organization = "yourdevops"
  }
}

resource "tls_locally_signed_cert" "aop_leaf" {
  cert_request_pem   = tls_cert_request.aop_leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.aop_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.aop_ca.cert_pem

  validity_period_hours = 87600 # ~10 years

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
  ]
}

# -----------------------------------------------------------------------------
# Cloudflare zone-level Authenticated Origin Pulls
# -----------------------------------------------------------------------------

resource "cloudflare_authenticated_origin_pulls_certificate" "this" {
  zone_id     = cloudflare_zone.this.id
  certificate = tls_locally_signed_cert.aop_leaf.cert_pem
  private_key = tls_private_key.aop_leaf.private_key_pem
}

resource "cloudflare_authenticated_origin_pulls_settings" "this" {
  zone_id = cloudflare_zone.this.id
  enabled = true
}
