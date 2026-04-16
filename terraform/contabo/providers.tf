terraform {
  required_version = ">= 1.5"

  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = ">= 0.1.32"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  cloud {
    organization = "yourdevops"
    workspaces {
      name = "contabo"
    }
  }
}

provider "contabo" {}
