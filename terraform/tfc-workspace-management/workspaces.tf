data "tfe_organization" "this" {
  name = "yourdevops"
}

data "tfe_project" "default" {
  organization = data.tfe_organization.this.name
  name         = "YourDevOps"
}

data "tfe_oauth_client" "github" {
  organization     = data.tfe_organization.this.name
  service_provider = "github"
}

import {
  to = tfe_workspace.this
  id = "${data.tfe_organization.this.name}/tfc-workspace-management"
}

resource "tfe_workspace" "this" {
  name         = "tfc-workspace-management"
  description  = "Manages other workspaces"
  organization = data.tfe_organization.this.name
  project_id   = data.tfe_project.default.id

  working_directory = "terraform/tfc-workspace-management/"
  auto_apply        = true

  vcs_repo {
    identifier     = "yourdevops/infra-k3s-contabo"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
}

resource "tfe_workspace" "cloudflare" {
  name         = "cloudflare"
  organization = data.tfe_organization.this.name
  project_id   = data.tfe_project.default.id

  working_directory = "terraform/cloudflare/"
  auto_apply        = true

  vcs_repo {
    identifier     = "yourdevops/infra-k3s-contabo"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
}

resource "tfe_variable" "cloudflare_api_token" {
  # Placeholder secret -- needs to be populated manually in TFC
  workspace_id = tfe_workspace.cloudflare.id
  key          = "CLOUDFLARE_API_TOKEN"
  value        = ""
  category     = "env"
  sensitive    = true

  lifecycle {
    ignore_changes = [value]
  }
}

resource "tfe_workspace" "contabo" {
  name         = "contabo"
  organization = data.tfe_organization.this.name
  project_id   = data.tfe_project.default.id

  working_directory = "terraform/contabo/"
  auto_apply        = false

  vcs_repo {
    identifier     = "yourdevops/infra-k3s-contabo"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
    branch         = "main"
  }
}
