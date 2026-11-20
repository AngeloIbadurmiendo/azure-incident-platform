terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.1"
    }
  }
}
provider "azurerm" {
  # El bloque features es obligatorio en el proveedor azurerm
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}
