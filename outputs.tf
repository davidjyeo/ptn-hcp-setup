output "workspace_ids" {
  value = {
    for env, ws in tfe_workspace.this : env => ws.id
  }
}
