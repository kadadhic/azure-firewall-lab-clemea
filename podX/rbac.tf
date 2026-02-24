# RBAC Role Assignments for Demo Users
# Grant access to resource groups and enable serial console access

# Data source to get demo user principal
data "azuread_user" "demo_user" {
  user_principal_name = var.user_principal_name
}

# Data source to reference NetworkWatcherRG (Azure auto-created resource group)
data "azurerm_resource_group" "network_watcher" {
  name = "NetworkWatcherRG"
}

# Grant Contributor role on main resource group
resource "azurerm_role_assignment" "demo_user_main_rg" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_user.demo_user.object_id
}

# Grant Contributor role on branch resource group
resource "azurerm_role_assignment" "demo_user_branch_rg" {
  scope                = azurerm_resource_group.branch.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_user.demo_user.object_id
}

# Grant Contributor role on NetworkWatcherRG
resource "azurerm_role_assignment" "demo_user_network_watcher_rg" {
  scope                = data.azurerm_resource_group.network_watcher.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_user.demo_user.object_id
}

# Grant Virtual Machine Contributor role for serial console access on main RG
resource "azurerm_role_assignment" "demo_user_vm_contributor_main" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azuread_user.demo_user.object_id
}

# Grant Virtual Machine Contributor role for serial console access on branch RG
resource "azurerm_role_assignment" "demo_user_vm_contributor_branch" {
  scope                = azurerm_resource_group.branch.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azuread_user.demo_user.object_id
}
