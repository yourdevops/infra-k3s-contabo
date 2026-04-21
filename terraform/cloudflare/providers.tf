terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  cloud {
    organization = "yourdevops"
    workspaces {
      name = "cloudflare"
    }
  }
}

provider "cloudflare" {
  # CLOUDFLARE_API_TOKEN variable has to be supplied to the executor
}
