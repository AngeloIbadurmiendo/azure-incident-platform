data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly_budget" {
  name            = "monthly-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"

    contact_emails = var.alert_emails
  }

  notification {
    enabled   = true
    threshold = 50
    operator  = "GreaterThan"

    contact_emails = var.alert_emails
  }

  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"

    contact_emails = var.alert_emails
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = var.alert_emails
  }
}
