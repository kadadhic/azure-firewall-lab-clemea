# Cisco FTDv Firewall Infrastructure
# Complete Azure deployment with userdata integration

# Management Public IPs for FTDv instances
resource "azurerm_public_ip" "ftdv1_mgmt" {
  name                = "${var.resource_prefix}-ftd76-1nic0-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags = merge(var.common_tags, {
    Purpose = "FTDv1 Management"
  })
}

resource "azurerm_public_ip" "ftdv2_mgmt" {
  name                = "${var.resource_prefix}-ftd76-2nic0-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["2"]
  tags = merge(var.common_tags, {
    Purpose = "FTDv2 Management"
  })
}

# Public IPs for Outside Interfaces
resource "azurerm_public_ip" "ftdv1_outside" {
  name                = "${var.resource_prefix}-ftd76-1nic1-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags = merge(var.common_tags, {
    Purpose = "FTDv1 Outside Interface"
  })
}

resource "azurerm_public_ip" "ftdv2_outside" {
  name                = "${var.resource_prefix}-ftd76-2nic1-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["2"]
  tags = merge(var.common_tags, {
    Purpose = "FTDv2 Outside Interface"
  })
}

# Network Interfaces for FTDv1
resource "azurerm_network_interface" "ftdv1_mgmt" {
  name                = "${var.resource_prefix}-ftd76-1-nic0"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv1_management_ip
    public_ip_address_id          = azurerm_public_ip.ftdv1_mgmt.id
  }
}

resource "azurerm_network_interface" "ftdv1_outside" {
  name                  = "${var.resource_prefix}-ftd76-1-nic1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_subnet.outside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv1_outside_ip
    public_ip_address_id          = azurerm_public_ip.ftdv1_outside.id
  }
}

resource "azurerm_network_interface" "ftdv1_inside" {
  name                  = "${var.resource_prefix}-ftd76-1-nic2"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "inside"
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv1_inside_ip
  }
}

# FTDv1 Virtual Machine
resource "azurerm_virtual_machine" "ftdv1" {
  name                = "${var.resource_prefix}-ftd76-1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  zones               = ["1"]

  primary_network_interface_id = azurerm_network_interface.ftdv1_mgmt.id
  network_interface_ids = [
    azurerm_network_interface.ftdv1_mgmt.id,
    azurerm_network_interface.ftdv1_outside.id,
    azurerm_network_interface.ftdv1_inside.id,
  ]
  vm_size = var.ftdv_vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  plan {
    name      = "ftdv-azure-byol"
    publisher = "cisco"
    product   = "cisco-ftdv"
  }

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-ftdv"
    sku       = "ftdv-azure-byol"
    version   = var.ftd_image_version
  }

  storage_os_disk {
    name              = "${var.resource_prefix}-ftd76-1-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "Azure-FTDv1"
    admin_username = var.ftdv_admin_username
    admin_password = var.ftdv_admin_password
    custom_data = templatefile("${path.module}/userdata/ftd_userdata.tftpl", {
      admin_password = var.ftdv_admin_password
      hostname       = "Azure-FTDv1"
      # fmc_ip         = sccfm_ftd_device.ftdv1.hostname
      # reg_key        = sccfm_ftd_device.ftdv1.reg_key
      # fmc_nat_id     = sccfm_ftd_device.ftdv1.nat_id
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = data.azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  tags = merge(var.common_tags, {
    Purpose = "FTDv1 Firewall"
    Zone    = "1"
  })
}

# Network Interfaces for FTDv2
resource "azurerm_network_interface" "ftdv2_mgmt" {
  name                = "${var.resource_prefix}-ftd76-2-nic0"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv2_management_ip
    public_ip_address_id          = azurerm_public_ip.ftdv2_mgmt.id
  }
}

resource "azurerm_network_interface" "ftdv2_outside" {
  name                  = "${var.resource_prefix}-ftd76-2-nic1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_subnet.outside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv2_outside_ip
    public_ip_address_id          = azurerm_public_ip.ftdv2_outside.id
  }
}

resource "azurerm_network_interface" "ftdv2_inside" {
  name                  = "${var.resource_prefix}-ftd76-2-nic2"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "inside"
    subnet_id                     = azurerm_subnet.inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftdv2_inside_ip
  }
}

# FTDv2 Virtual Machine
resource "azurerm_virtual_machine" "ftdv2" {
  name                = "${var.resource_prefix}-ftd76-2"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  zones               = ["2"]

  primary_network_interface_id = azurerm_network_interface.ftdv2_mgmt.id
  network_interface_ids = [
    azurerm_network_interface.ftdv2_mgmt.id,
    azurerm_network_interface.ftdv2_outside.id,
    azurerm_network_interface.ftdv2_inside.id,
  ]
  vm_size = var.ftdv_vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  plan {
    name      = "ftdv-azure-byol"
    publisher = "cisco"
    product   = "cisco-ftdv"
  }

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-ftdv"
    sku       = "ftdv-azure-byol"
    version   = var.ftd_image_version
  }

  storage_os_disk {
    name              = "${var.resource_prefix}-ftd76-2-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "Azure-FTDv2"
    admin_username = var.ftdv_admin_username
    admin_password = var.ftdv_admin_password
    custom_data = templatefile("${path.module}/userdata/ftd_userdata.tftpl", {
      admin_password = var.ftdv_admin_password
      hostname       = "Azure-FTDv2"
      # fmc_ip         = sccfm_ftd_device.ftdv2.hostname
      # reg_key        = sccfm_ftd_device.ftdv2.reg_key
      # fmc_nat_id     = sccfm_ftd_device.ftdv2.nat_id
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = data.azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  tags = merge(var.common_tags, {
    Purpose = "FTDv2 Firewall"
    Zone    = "2"
  })
}