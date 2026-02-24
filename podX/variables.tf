# Resource Naming
variable "resource_prefix" {
  description = "Prefix for all Azure resource names"
  type        = string
  default     = "podX"
}

# Azure Region
variable "azure_region" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# Security Configuration
variable "trusted_networks" {
  description = "List of trusted network CIDR blocks allowed for inbound traffic"
  type        = list(string)
  default = [
    "172.0.0.0/8",
    "192.0.0.0/8",
    "10.0.0.0/8",
    "151.0.0.0/8"
  ]
}

# Virtual Network CIDR Blocks
variable "security_vnet_cidr" {
  description = "CIDR block for Security VNet"
  type        = string
  default     = "10.100.0.0/16"
}

variable "spoke1_vnet_cidr" {
  description = "CIDR block for Spoke1 VNet"
  type        = string
  default     = "10.101.0.0/16"
}

variable "spoke2_vnet_cidr" {
  description = "CIDR block for Spoke2 VNet"
  type        = string
  default     = "10.102.0.0/16"
}

# Security VNet Subnet CIDRs
variable "management_subnet_cidr" {
  description = "CIDR block for Management subnet in Security VNet"
  type        = string
  default     = "10.100.250.0/24"
}

variable "inside_subnet_cidr" {
  description = "CIDR block for Inside subnet in Security VNet"
  type        = string
  default     = "10.100.100.0/24"
}

variable "outside_subnet_cidr" {
  description = "CIDR block for Outside subnet in Security VNet"
  type        = string
  default     = "10.100.200.0/24"
}

# Spoke VNet Subnet CIDRs
variable "spoke1_web_subnet_cidr" {
  description = "CIDR block for web subnet in Spoke1 VNet"
  type        = string
  default     = "10.101.101.0/24"
}

variable "spoke1_app_subnet_cidr" {
  description = "CIDR block for app subnet in Spoke1 VNet"
  type        = string
  default     = "10.101.102.0/24"
}

variable "spoke1_db_subnet_cidr" {
  description = "CIDR block for db subnet in Spoke1 VNet"
  type        = string
  default     = "10.101.103.0/24"
}

variable "spoke2_app_subnet_cidr" {
  description = "CIDR block for app subnet in Spoke2 VNet"
  type        = string
  default     = "10.102.102.0/24"
}

# Branch VNet Configuration
variable "branch_vnet_cidr" {
  description = "CIDR block for Branch VNet"
  type        = string
  default     = "192.168.0.0/16"
}

variable "branch_management_subnet_cidr" {
  description = "CIDR block for management subnet in Branch VNet"
  type        = string
  default     = "192.168.250.0/24"
}

variable "branch_inside_subnet_cidr" {
  description = "CIDR block for inside subnet in Branch VNet"
  type        = string
  default     = "192.168.100.0/24"
}

variable "branch_outside_subnet_cidr" {
  description = "CIDR block for outside subnet in Branch VNet"
  type        = string
  default     = "192.168.200.0/24"
}

variable "branch_app_subnet_cidr" {
  description = "CIDR block for app subnet in Branch VNet"
  type        = string
  default     = "192.168.102.0/24"
}

# FTDv Firewall IP Addresses
variable "ftdv1_management_ip" {
  description = "Management IP for FTDv1 firewall (nic0)"
  type        = string
  default     = "10.100.250.81"
}

variable "ftdv1_inside_ip" {
  description = "Inside IP for FTDv1 firewall (nic1)"
  type        = string
  default     = "10.100.100.81"
}

variable "ftdv1_outside_ip" {
  description = "Outside IP for FTDv1 firewall (nic2)"
  type        = string
  default     = "10.100.200.81"
}

variable "ftdv2_management_ip" {
  description = "Management IP for FTDv2 firewall (nic0)"
  type        = string
  default     = "10.100.250.82"
}

variable "ftdv2_inside_ip" {
  description = "Inside IP for FTDv2 firewall (nic1)"
  type        = string
  default     = "10.100.100.82"
}

variable "ftdv2_outside_ip" {
  description = "Outside IP for FTDv2 firewall (nic2)"
  type        = string
  default     = "10.100.200.82"
}

# Branch FTDv IP Addresses
variable "branch_ftdv_management_ip" {
  description = "Management IP for Branch FTDv firewall"
  type        = string
  default     = "192.168.250.4"
}

variable "branch_ftdv_inside_ip" {
  description = "Inside IP for Branch FTDv firewall"
  type        = string
  default     = "192.168.100.4"
}

variable "branch_ftdv_outside_ip" {
  description = "Outside IP for Branch FTDv firewall"
  type        = string
  default     = "192.168.200.4"
}

variable "branch_app_vm_ip" {
  description = "IP address for Branch application VM"
  type        = string
  default     = "192.168.102.100"
}

# FTDv Configuration
variable "ftdv_vm_size" {
  description = "Azure VM size for FTDv instances"
  type        = string
  default     = "Standard_D3_v2"
}

variable "ftdv_admin_username" {
  description = "Admin username for FTDv instances"
  type        = string
  default     = "cisco"
}

variable "ftdv_admin_password" {
  description = "Admin password for FTDv instances"
  type        = string
  sensitive   = true
}

# Test VM Configuration
variable "vm_size" {
  description = "Azure VM size for test VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for test VMs"
  type        = string
  default     = "ubuntu"
}

variable "admin_password" {
  description = "Admin password for test VMs"
  type        = string
  sensitive   = true
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "merck-automation"
    Owner       = "terraform"
  }
}
variable "ftd_image_version" {
  description = "FTDv image version"
  type        = string
  default     = "762329.0.0"
}
variable "user_principal_name" {
  description = "User principal name for the demo user"
}