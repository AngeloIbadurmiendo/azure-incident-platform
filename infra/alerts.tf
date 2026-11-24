resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.resource_group_name}-dev"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "incidents"
  tags                = { project = "incident-platform" }
  email_receiver {
    name          = "email"
    email_address = var.alert_emails[0]
  }
}

resource "azurerm_monitor_metric_alert" "failed_request" {
  name                = "ma-${var.resource_group_name}-failed-request-dev"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.api.id]
  description         = "Alert for failed requests"
  severity            = "1"
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = { project = "incident-platform" }

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 3

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["5xx"]
    }
  }
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_metric_alert" "high_latency" {
  name                = "ma-${var.resource_group_name}-high-latency-dev"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert for high latency"
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = { project = "incident-platform" }

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_metric_alert" "container_restart" {
  name                = "ma-${var.resource_group_name}-container-restart-dev"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_app.api.id]
  description         = "Alert for container restarts"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = { project = "incident-platform" }

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "RestartCount"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 2

  }
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
