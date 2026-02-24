# Azure Deployment Outputs
# Key information for the Azure VNet Peering + FTDv architecture

output "security_vnet_id" {
  description = "Security VNet ID"
  value       = azurerm_virtual_network.security.id
}

output "security_vnet_cidr" {
  description = "Security VNet CIDR block"
  value       = var.security_vnet_cidr
}

output "spoke1_vnet_id" {
  description = "Spoke1 VNet ID"
  value       = azurerm_virtual_network.spoke1.id
}

output "spoke1_vnet_cidr" {
  description = "Spoke1 VNet CIDR block"
  value       = var.spoke1_vnet_cidr
}

output "spoke2_vnet_id" {
  description = "Spoke2 VNet ID"
  value       = azurerm_virtual_network.spoke2.id
}

output "spoke2_vnet_cidr" {
  description = "Spoke2 VNet CIDR block"
  value       = var.spoke2_vnet_cidr
}

output "branch_vnet_id" {
  description = "Branch VNet ID"
  value       = azurerm_virtual_network.branch.id
}

output "branch_vnet_cidr" {
  description = "Branch VNet CIDR block"
  value       = var.branch_vnet_cidr
}

output "spoke1_web_vm_private_ip" {
  description = "Private IP address of Spoke1 web VM"
  value       = azurerm_network_interface.spoke1_web.private_ip_address
}

output "spoke1_web_vm_public_ip" {
  description = "Public IP address of Spoke1 web VM"
  value       = azurerm_public_ip.spoke1_web.ip_address
}

output "spoke1_app_vm_private_ip" {
  description = "Private IP address of Spoke1 app VM"
  value       = azurerm_network_interface.spoke1_app.private_ip_address
}

output "spoke1_db_vm_private_ip" {
  description = "Private IP address of Spoke1 database VM"
  value       = azurerm_network_interface.spoke1_db.private_ip_address
}

output "spoke2_app2a_vm_private_ip" {
  description = "Private IP address of Spoke2 app2a VM"
  value       = azurerm_network_interface.spoke2_app2a.private_ip_address
}

output "spoke2_app2b_vm_private_ip" {
  description = "Private IP address of Spoke2 app2b VM"
  value       = azurerm_network_interface.spoke2_app2b.private_ip_address
}

output "branch_ftdv_management_ip" {
  description = "FTDv firewall management IP addresses"
  value = {
    ftdv1_mgmt_ip = var.ftdv1_management_ip
    ftdv2_mgmt_ip = var.ftdv2_management_ip
  }
}

output "ftdv_management_public_ips" {
  description = "FTDv firewall management public IP addresses"
  value = {
    ftdv1_mgmt_public_ip       = azurerm_public_ip.ftdv1_mgmt.ip_address
    ftdv2_mgmt_public_ip       = azurerm_public_ip.ftdv2_mgmt.ip_address
    branch_ftdv_mgmt_public_ip = azurerm_public_ip.branch_ftdv_mgmt.ip_address
  }
}

output "ftdv_outside_public_ips" {
  description = "FTDv firewall outside interface public IP addresses"
  value = {
    ftdv1_outside_public_ip       = azurerm_public_ip.ftdv1_outside.ip_address
    ftdv2_outside_public_ip       = azurerm_public_ip.ftdv2_outside.ip_address
    branch_ftdv_outside_public_ip = azurerm_public_ip.branch_ftdv_outside.ip_address
  }
}

output "branch_app_vm_public_ip" {
  description = "Branch App VM Public IP"
  value       = azurerm_public_ip.branch_app_vm.ip_address
}

output "subnet_cidrs" {
  description = "All subnet CIDR blocks"
  value = {
    management_subnet        = var.management_subnet_cidr
    inside_subnet            = var.inside_subnet_cidr
    outside_subnet           = var.outside_subnet_cidr
    spoke1_web_subnet        = var.spoke1_web_subnet_cidr
    spoke1_app_subnet        = var.spoke1_app_subnet_cidr
    spoke1_db_subnet         = var.spoke1_db_subnet_cidr
    spoke2_app_subnet        = var.spoke2_app_subnet_cidr
    branch_management_subnet = var.branch_management_subnet_cidr
    branch_inside_subnet     = var.branch_inside_subnet_cidr
    branch_outside_subnet    = var.branch_outside_subnet_cidr
    branch_app_subnet        = var.branch_app_subnet_cidr
  }
}

# Route table and VNet peering outputs removed - to be configured via Azure Portal UI

output "deployment_summary" {
  description = "Summary of Azure deployment architecture"
  value = {
    architecture       = "Azure VNet Peering with Cisco FTDv centralized inspection + Branch site"
    security_model     = "Hub-and-spoke with security VNet inspection + Branch FTDv"
    firewall_count     = 3
    firewall_names     = ["FTDv1", "FTDv2", "Branch-FTDv"]
    availability_zones = ["Zone 1", "Zone 2"]
    spoke_count        = 2
    branch_sites       = 1
    test_vms           = 6
    spoke1_vms         = ["web", "app", "db"]
    spoke2_vms         = ["app2a", "app2b"]
    branch_vms         = ["app"]
    mgmt_vms           = ["jumpbox"]
  }
}