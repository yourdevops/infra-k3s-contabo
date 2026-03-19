terraform {
  required_version = ">= 1.5"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.74"
    }
  }

  cloud {

    organization = "yourdevops"

    workspaces {
      name = "tfc-workspace-management"
    }
  }
}

provider "tfe" {}
