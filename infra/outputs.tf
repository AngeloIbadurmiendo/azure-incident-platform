output "api_url" {
  description = "url of API container app"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "postgres_fqdn" {
  description = "fqdn of psql flex server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "res_group_name" {
  description = "name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "app_insights_connection_string" {
  description = "connection string for App Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}
