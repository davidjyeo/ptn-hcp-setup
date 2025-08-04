// Create a Project
resource "tfe_project" "this" {
  name         = var.project_name
  organization = var.organization
  description  = "Better Description Required"
}

// Create a Workspace for each environement
resource "tfe_workspace" "this" {
  for_each       = toset(var.environments)
  name           = "${var.project_name}-${each.key}"
  organization   = var.organization
  project_id     = tfe_project.this.id
  queue_all_runs = true
  description    = "Better Description Required"
}

// Create a team for the workspace
resource "tfe_team" "this" {
  for_each     = toset(var.environments)
  name         = "${tfe_workspace.this[each.key].name}-run-team"
  organization = var.organization
}

// Create a team access for the workspace
resource "tfe_team_access" "this" {
  for_each     = toset(var.environments)
  access       = "write"
  team_id      = tfe_team.this[each.key].id
  workspace_id = tfe_workspace.this[each.key].id
}

ephemeral "tfe_team_token" "this" {
  for_each = toset(var.environments)
  team_id  = tfe_team.this[each.key].id
}

// Create a variable set for the workspace
resource "tfe_variable_set" "this" {
  for_each     = toset(var.environments)
  name         = "${tfe_workspace.this[each.key].name}-ws-varset"
  description  = "OIDC federation configuration for ${tfe_workspace.this[each.key].name}."
  organization = var.organization
}

// Create a variable for the Azure Provider Auth
resource "tfe_variable" "tfc_azure_provider_auth" {
  for_each        = toset(var.environments)
  key             = "TFC_AZURE_PROVIDER_AUTH"
  value           = var.tfc_azure_provider_auth
  category        = "env"
  variable_set_id = tfe_variable_set.this[each.key].id
}

// Create a variable for the Azure Run Client ID
resource "tfe_variable" "tfc_azure_run_client_id" {
  for_each        = toset(var.environments)
  sensitive       = false
  key             = "TFC_AZURE_RUN_CLIENT_ID"
  value           = "null" #azuread_application_registration.this.client_id
  category        = "env"
  variable_set_id = tfe_variable_set.this[each.key].id
}
