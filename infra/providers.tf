terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.14.0"
    }
  }
}
provider "azurerm" {
  # El bloque features es obligatorio en el proveedor azurerm
  features {}
}
