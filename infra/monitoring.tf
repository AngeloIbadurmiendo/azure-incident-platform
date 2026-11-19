resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.resource_group_name}-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = { project = "incident-platform" }
  daily_quota_gb      = 0.5
}
