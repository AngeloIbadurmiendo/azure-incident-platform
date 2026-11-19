resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.resource_group_name}-dev"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = { project = "incident-platform" }
}
