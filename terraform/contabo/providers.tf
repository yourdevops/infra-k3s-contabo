terraform {
  required_version = ">= 1.5"

  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = ">= 0.1.32"
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
