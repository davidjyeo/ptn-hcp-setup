// Azure DevOps Resources
resource "azuredevops_project" "this" {
  # name               = tfe_workspace.this.name
  name               = var.project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = "Managed by Terraform"
  # features = {
  #   testplans = "disabled"
  #   artifacts = "disabled"
  # }
}

resource "azuredevops_variable_group" "this" {
  for_each     = toset(var.environments)
  project_id   = azuredevops_project.this.id
  name         = each.key
  description  = "Variables for Project ${var.project_name}, Environment ${each.key}."
  allow_access = true

  variable {
    name  = "TF_TOKEN"
    value = "null" #tfe_team_token.this.token
    # is_secret = true
  }
}

data "azuredevops_git_repository" "this" {
  project_id = azuredevops_project.this.id
  name       = "plat-fs"
  # default_branch = "refs/heads/main"
}

# terraform import azuredevops_git_repository.example projectName/00000000-0000-0000-0000-000000000000

# import {
#   id = "${azuredevops_project.this.name}/${data.azuredevops_git_repository.this.name}"
#   to = azuredevops_git_repository.this
# }

# output "sasasas" {
#   value = data.azuredevops_git_repository.this
# }


resource "azuredevops_git_repository" "this" {
  project_id     = azuredevops_project.this.id
  name           = data.azuredevops_git_repository.this.name
  default_branch = "refs/heads/main"
  initialization {
    init_type   = "import"
    source_type = git
    source_url  = data.azuredevops_git_repository.this.url
  }
  lifecycle {
    ignore_changes = [
      # Ignore changes to initialization to support importing existing repositories
      # Given that a repo now exists, either imported into terraform state or created by terraform,
      # we don't care for the configuration of initialization against the existing resource
      initialization,
    ]
  }
}


# resource "azuredevops_project" "this" {
#   name               = tfe_workspace.this.name
#   visibility         = "private"
#   version_control    = "Git"
#   work_item_template = "Agile"
#   description        = "Managed by Terraform"
#   features = {
#     boards    = "disabled"
#     testplans = "disabled"
#     artifacts = "disabled"
#   }
# }

# # data "azuredevops_agent_pool" "this" {
# #   name = "msamlin-selfhosted"
# # }

# # resource "azuredevops_agent_queue" "this" {
# #   project_id    = azuredevops_project.this.id
# #   agent_pool_id = data.azuredevops_agent_pool.this.id
# # }

# # resource "azuredevops_resource_authorization" "this" {
# #   project_id  = azuredevops_project.this.id
# #   resource_id = data.azuredevops_agent_pool.this.id
# #   type        = "queue"
# #   authorized  = true
# # }

# # data "azuredevops_team" "this" {
# #   project_id = azuredevops_project.this.id
# #   name       = "${tfe_workspace.this.name} Team"
# # }

# # data "azuredevops_group" "this" {
# #   project_id = azuredevops_project.this.id
# #   name       = "${tfe_workspace.this.name} Team"
# # }

# # resource "azuredevops_team_members" "this" {
# #   project_id = azuredevops_project.this.id
# #   team_id    = data.azuredevops_team.this.id
# #   # mode       = "overwrite"
# #   members = [
# #   ]
# # }

# // Create a git repository in ADO for the workspace
# resource "azuredevops_git_repository" "this" {
#   project_id     = azuredevops_project.this.id
#   name           = "${tfe_workspace.this.name}-infrastructure"
#   default_branch = "refs/heads/main"
#   initialization {
#     init_type = "Clean"
#   }
# }

# // Create a git repository file in ADO for the workspace
# resource "azuredevops_git_repository_file" "this" {
#   repository_id = azuredevops_git_repository.this.id
#   file          = ".pipelines/azure-pipelines.yml"

#   content             = <<-EOT
#     trigger: none
#     # - main

#     pool: msamlin-selfhosted

#     variables:
#       terraformVersion: "latest"
#       terraformWorkingDirectory: "$(Build.SourcesDirectory)/terraform"

#     stages:
#       - stage: "tfc_plan"
#         variables:
#         - group: "${azuredevops_variable_group.this.name}"
#         displayName: HCP Terraform - Plan
#         jobs:
#           - job: planTerraform
#             displayName: Plan Terraform
#             steps:
#               - task: TerraformInstaller@2
#                 displayName: "Terraform Install - Latest"
#                 inputs:
#                   terraformVersion: "$(terraformVersion)"

#               - task: Bash@3
#                 displayName: "Terraform Plan"
#                 inputs:
#                   targetType: "inline"
#                   script: |
#                     echo ""
#                     echo "####################"
#                     echo "## Terraform Plan ##"
#                     echo "####################"
#                     echo ""

#                     export TF_TOKEN_app_terraform_io="$(TF_TOKEN)"
#                     terraform init -input=false -upgrade
#                     terraform plan
#                   workingDirectory: "$(terraformWorkingDirectory)"

#       - stage: "tfc_deploy"
#         variables:
#           - group: "${azuredevops_variable_group.this.name}"
#         displayName: Deploy
#         jobs:
#           - deployment: deployTerraform
#             displayName: HCP Terraform - Apply
#             environment: hcp_terraform
#             strategy:
#               runOnce:
#                 deploy:
#                   steps:
#                     - task: TerraformInstaller@2
#                       displayName: "Terraform Install - Latest"
#                       inputs:
#                         terraformVersion: "$(terraformVersion)"

#                     - task: Bash@3
#                       displayName: "Terraform Init"
#                       inputs:
#                         targetType: "inline"
#                         script: |
#                           echo ""
#                           echo "####################"
#                           echo "## Terraform Init ##"
#                           echo "####################"
#                           echo ""

#                           export TF_TOKEN_app_terraform_io="$(TF_TOKEN)"
#                           terraform init -input=false -upgrade
#                           terraform apply --auto-approve
#                         workingDirectory: "$(terraformWorkingDirectory)"
#   EOT
#   branch              = azuredevops_git_repository.this.default_branch
#   overwrite_on_create = false
# }

# // Create a provider.tf file in ADO for the workspace
# resource "azuredevops_git_repository_file" "tf_provider" {
#   repository_id = azuredevops_git_repository.this.id
#   file          = "terraform/provider.tf"

#   content = <<-EOT
#     terraform {
#       required_providers {
#         azurerm = {
#           source = "hashicorp/azurerm"
#         }
#         azapi = {
#           source = "azure/azapi"
#         }
#         random = {
#           source = "hashicorp/random"
#         }
#       }

#       backend "remote" {
#         organization = "MSAmlin"
#         workspaces {
#           name = "${tfe_workspace.this.name}"
#         }
#       }
#     }

#     provider "azurerm" {
#       features {
#         virtual_machine {
#           delete_os_disk_on_deletion     = true
#           skip_shutdown_and_force_delete = true
#         }
#         resource_group {
#           prevent_deletion_if_contains_resources = true
#         }
#       }
#       storage_use_azuread = true
#     }

#     provider "azapi" {}

#     data "azurerm_subscription" "this" {}
#     data "azurerm_client_config" "this" {}
#   EOT

#   branch              = azuredevops_git_repository.this.default_branch
#   overwrite_on_create = false
# }

# // Create a variable group for the workspace
# resource "azuredevops_variable_group" "this" {
#   project_id   = azuredevops_project.this.id
#   name         = "${var.workspace_name}-${var.suffix}"
#   description  = "Variables for ${var.workspace_name}-${var.suffix}."
#   allow_access = true

#   variable {
#     name  = "TF_TOKEN"
#     value = tfe_team_token.this.token
#   }
# }
