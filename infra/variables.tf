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
    error_message = "Debe haber al menos un correo"
  }
}

variable "location" {
  description = "Ubicación de los recursos"
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "Nombre del proyecto de incidentes"
  type        = string
  default     = "incidents"
}

variable "database_username" {
  description = "Nombre de usuario postgres db"
  type        = string
  default     = "incidentsadmin"
}

variable "resource_sufix" {
  description = "Sufijo para los recursos"
  type        = string
  default     = "ai01"
}

variable "container_app_image" {
  description = "Imagen del contenedor"
  type        = string
  default     = "ghcr.io/angeloibadurmiendo/azure-incident-platform:0.1.0"
}
