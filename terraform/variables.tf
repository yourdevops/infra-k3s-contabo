variable "cloudflare_api_token" {
  description = "Cloudflare API token (Zone:DNS:Edit, Account:Cloudflare Tunnel:Edit)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "domain" {
  description = "Base domain"
  type        = string
  default     = "yourdevops.me"
}
