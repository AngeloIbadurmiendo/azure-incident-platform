resource "azurerm_resource_group" "main" {
  name     = "rg-${var.resource_group_name}-dev"
  location = var.location
  tags     = { project = "incident-platform" }
}
