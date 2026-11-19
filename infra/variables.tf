variable "budget_amount" {
  description = "Monto de presupuesto."
  type        = number

  validation {
    condition     = var.budget_amount > 0
    error_message = "El monto de (budget_amount) debe ser mayor que 0."
  }
}

variable "alert_emails" {
  description = "lista de emails de alertas"
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "Debes haber al menos un correo electrónico"
  }
}
