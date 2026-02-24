# Resource Group for Azure VNet Peering Architecture

# Main Resource Group for Hub and Spoke VNets
resource "azurerm_resource_group" "main" {
  name     = var.resource_prefix
  location = var.azure_region
  tags = merge(var.common_tags, {
    Purpose = "Hub and Spoke Network Infrastructure"
  })
}

# Branch Resource Group
resource "azurerm_resource_group" "branch" {
  name     = "${var.resource_prefix}-branch"
  location = var.azure_region
  tags = merge(var.common_tags, {
    Purpose = "Branch Site Infrastructure"
    Site    = "Branch"
  })
}

# Aliases for backward compatibility
locals {
  resource_group_name     = azurerm_resource_group.main.name
  resource_group_location = azurerm_resource_group.main.location
}

# Legacy references for easier migration
resource "null_resource" "rg_aliases" {
  triggers = {
    security = azurerm_resource_group.main.name
    spoke1   = azurerm_resource_group.main.name
    spoke2   = azurerm_resource_group.main.name
  }
}

# Reference existing storage account for boot diagnostics
data "azurerm_storage_account" "boot_diagnostics" {
  name                = "cl26emealtrsec2683sa"
  resource_group_name = "LabImages-rg"
}