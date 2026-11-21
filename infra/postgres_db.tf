resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "-_"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.resource_group_name}-dev-${var.resource_sufix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = var.database_username
  administrator_password = random_password.password.result
  tags                   = { project = "incident-platform" }
  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  storage_mb = 32768
  sku_name   = "B_Standard_B1ms"
}

resource "azurerm_postgresql_flexible_server_database" "app_db" {
  name      = "incidents"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "utf8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow_azure_services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
