# Security VNet Infrastructure
# This VNet hosts the Cisco FTDv firewalls for centralized security inspection

# Security Virtual Network
resource "azurerm_virtual_network" "security" {
  name                = "${var.resource_prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.security_vnet_cidr]
  tags                = var.common_tags
}

# Management Subnet - For FTDv management interfaces
resource "azurerm_subnet" "management" {
  name                 = "${var.resource_prefix}-management-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = [var.management_subnet_cidr]

  # Allow management traffic from NSG
  service_endpoints = ["Microsoft.Storage"]
}

# Inside Subnet - For FTDv inside/trust interfaces
resource "azurerm_subnet" "inside" {
  name                 = "${var.resource_prefix}-inside-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = [var.inside_subnet_cidr]
}

# Outside Subnet - For FTDv outside/untrust interfaces
resource "azurerm_subnet" "outside" {
  name                 = "${var.resource_prefix}-outside-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = [var.outside_subnet_cidr]
}

# Network Security Group for Management Subnet
resource "azurerm_network_security_group" "management" {
  name                = "${var.resource_prefix}-management-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  # Allow all inbound traffic from trusted networks only
  security_rule {
    name                       = "AllowTrustedNetworksInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.trusted_networks
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic to any destination
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Outside Subnet
resource "azurerm_network_security_group" "outside" {
  name                = "${var.resource_prefix}-outside-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  # Allow inbound traffic only from trusted networks
  security_rule {
    name                       = "AllowTrustedNetworksInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.trusted_networks
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic to any destination
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Inside Subnet
resource "azurerm_network_security_group" "inside" {
  name                = "${var.resource_prefix}-inside-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  # Allow inbound traffic only from trusted networks
  security_rule {
    name                       = "AllowTrustedNetworksInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = var.trusted_networks
    destination_address_prefix = "*"
  }

  # Allow all outbound traffic to any destination
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Route Table for Inside Subnet
# Route tables removed - to be configured via Azure Portal UI

# Associate Management subnet with NSG
resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

# Associate Outside subnet with NSG and Route Table
resource "azurerm_subnet_network_security_group_association" "outside" {
  subnet_id                 = azurerm_subnet.outside.id
  network_security_group_id = azurerm_network_security_group.outside.id
}

# Associate Inside subnet with NSG
resource "azurerm_subnet_network_security_group_association" "inside" {
  subnet_id                 = azurerm_subnet.inside.id
  network_security_group_id = azurerm_network_security_group.inside.id
}

# Public IP for Management Jump Box
resource "azurerm_public_ip" "mgmt_jumpbox" {
  name                = "${var.resource_prefix}-jumpbox-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = merge(var.common_tags, {
    Purpose = "Management Jump Box"
  })
}

# Network Interface for Management Jump Box
resource "azurerm_network_interface" "mgmt_jumpbox" {
  name                = "${var.resource_prefix}-jumpbox-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt_jumpbox.id
  }
}

# Management Jump Box VM
resource "azurerm_linux_virtual_machine" "mgmt_jumpbox" {
  name                            = "${var.resource_prefix}-jumpbox"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "Management/Jump Box"
    Tier    = "Management"
  })

  network_interface_ids = [
    azurerm_network_interface.mgmt_jumpbox.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  # Install management tools
  custom_data = base64encode(<<-EOF
#cloud-config
package_update: true
package_upgrade: false

packages:
  - net-tools
  - vim
  - iputils-ping
  - sshpass
  - curl
  - wget
  - tcpdump
  - nmap
  - htop
  - git
  - openssh-server
  - ansible
  - python3-pip

write_files:
  - path: /etc/motd
    content: |
      ╔══════════════════════════════════════╗
      ║   MANAGEMENT JUMP BOX               ║
      ║   Security VNet - Management Subnet ║
      ║   Tools: ssh, ansible, nmap, az cli ║
      ╚══════════════════════════════════════╝

  - path: /home/ubuntu/connect.sh
    permissions: '0755'
    content: |
      #!/bin/bash

      echo "Here are the available devices:"
      echo "1) podx-ftd76-1"
      echo "2) podx-ftd76-2"
      echo "3) podX-spoke1-app"
      echo "4) podX-spoke1-db"
      echo "5) podX-spoke1-web"
      echo "6) podX-spoke2-app2a"
      echo "7) podX-spoke2-app2b"

      read -p "Enter the number or name of the device you wish to connect to: " selection

      # ⚠️  LAB-ONLY CREDENTIAL — 'Cisco@123' is intentional for this controlled lab environment.
      # Do NOT copy this credential into production templates or scripts.
      case "$selection" in
          1|podx-ftd76-1)
              echo "Connecting to podx-ftd76-1 (10.100.250.81) as admin..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@10.100.250.81
              ;;
          2|podx-ftd76-2)
              echo "Connecting to podx-ftd76-2 (10.100.250.82) as admin..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@10.100.250.82
              ;;
          3|podX-spoke1-app)
              echo "Connecting to podX-spoke1-app (10.101.102.100) as ubuntu..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.101.102.100
              ;;
          4|podX-spoke1-db)
              echo "Connecting to podX-spoke1-db (10.101.103.100) as ubuntu..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.101.103.100
              ;;
          5|podX-spoke1-web)
              echo "Connecting to podX-spoke1-web (10.101.101.100) as ubuntu..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.101.101.100
              ;;
          6|podX-spoke2-app2a)
              echo "Connecting to podX-spoke2-app2a (10.102.102.101) as ubuntu..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.102.102.101
              ;;
          7|podX-spoke2-app2b)
              echo "Connecting to podX-spoke2-app2b (10.102.102.102) as ubuntu..."
              sshpass -p 'Cisco@123' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.102.102.102
              ;;
          *)
              echo "error-occured: Invalid selection."
              ;;
      esac

runcmd:
  - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
  - echo "ubuntu:Cisco@123" | chpasswd
  - systemctl restart sshd
  - chown ubuntu:ubuntu /home/ubuntu/connect.sh
  - chmod u+x /home/ubuntu/connect.sh
  - echo "Management jump box setup complete" > /var/log/bootstrap.log
EOF
  )
}

