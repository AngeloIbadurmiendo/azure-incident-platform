resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.resource_group_name}-dev"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = { project = "incident-platform" }
}

resource "azurerm_container_app" "api" {
  name                         = "ca-${var.resource_group_name}-api-dev"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = { project = "incident-platform" }

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }

  secret {
    name  = "database-url"
    value = "postgresql+psycopg://${var.database_username}:${random_password.password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.app_db.name}?sslmode=require"
  }
  secret {
    name  = "appinsights-connection-string"
    value = azurerm_application_insights.main.connection_string
  }
  template {
    container {
      name   = "api"
      image  = var.container_app_image
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      readiness_probe {
        transport = "HTTP"
        port      = 8000
        path      = "/health"
      }
      liveness_probe {
        transport     = "HTTP"
        port          = 8000
        path          = "/health"
        initial_delay = 10
      }
    }
    min_replicas = 0
    max_replicas = 2
  }
  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
