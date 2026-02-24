# Branch VNet Infrastructure
# Branch site with one FTDv firewall and application VM

# Branch Virtual Network
resource "azurerm_virtual_network" "branch" {
  name                = "${var.resource_prefix}-branch-vnet"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  address_space       = [var.branch_vnet_cidr]
  tags = merge(var.common_tags, {
    Site = "Branch"
  })
}

# Branch Management Subnet
resource "azurerm_subnet" "branch_management" {
  name                 = "${var.resource_prefix}-branch-management-subnet"
  resource_group_name  = azurerm_resource_group.branch.name
  virtual_network_name = azurerm_virtual_network.branch.name
  address_prefixes     = [var.branch_management_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]
}

# Branch Inside Subnet
resource "azurerm_subnet" "branch_inside" {
  name                 = "${var.resource_prefix}-branch-inside-subnet"
  resource_group_name  = azurerm_resource_group.branch.name
  virtual_network_name = azurerm_virtual_network.branch.name
  address_prefixes     = [var.branch_inside_subnet_cidr]
}

# Branch Outside Subnet
resource "azurerm_subnet" "branch_outside" {
  name                 = "${var.resource_prefix}-branch-outside-subnet"
  resource_group_name  = azurerm_resource_group.branch.name
  virtual_network_name = azurerm_virtual_network.branch.name
  address_prefixes     = [var.branch_outside_subnet_cidr]
}

# Branch Application Subnet
resource "azurerm_subnet" "branch_app" {
  name                 = "${var.resource_prefix}-branch-app-subnet"
  resource_group_name  = azurerm_resource_group.branch.name
  virtual_network_name = azurerm_virtual_network.branch.name
  address_prefixes     = [var.branch_app_subnet_cidr]
}

# Network Security Groups for Branch Subnets
resource "azurerm_network_security_group" "branch_management" {
  name                = "${var.resource_prefix}-branch-management-nsg"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

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

resource "azurerm_network_security_group" "branch_inside" {
  name                = "${var.resource_prefix}-branch-inside-nsg"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

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

resource "azurerm_network_security_group" "branch_outside" {
  name                = "${var.resource_prefix}-branch-outside-nsg"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

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

resource "azurerm_network_security_group" "branch_app" {
  name                = "${var.resource_prefix}-branch-app-nsg"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

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

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "branch_management" {
  subnet_id                 = azurerm_subnet.branch_management.id
  network_security_group_id = azurerm_network_security_group.branch_management.id
}

resource "azurerm_subnet_network_security_group_association" "branch_inside" {
  subnet_id                 = azurerm_subnet.branch_inside.id
  network_security_group_id = azurerm_network_security_group.branch_inside.id
}

resource "azurerm_subnet_network_security_group_association" "branch_outside" {
  subnet_id                 = azurerm_subnet.branch_outside.id
  network_security_group_id = azurerm_network_security_group.branch_outside.id
}

resource "azurerm_subnet_network_security_group_association" "branch_app" {
  subnet_id                 = azurerm_subnet.branch_app.id
  network_security_group_id = azurerm_network_security_group.branch_app.id
}

# Public IPs for Branch FTDv
resource "azurerm_public_ip" "branch_ftdv_mgmt" {
  name                = "${var.resource_prefix}-branch-ftdv-mgmt-ip"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = merge(var.common_tags, {
    Purpose = "Branch FTDv Management"
  })
}

resource "azurerm_public_ip" "branch_ftdv_outside" {
  name                = "${var.resource_prefix}-branch-ftdv-outside-ip"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = merge(var.common_tags, {
    Purpose = "Branch FTDv Outside Interface"
  })
}

# Public IP for Branch Application VM
resource "azurerm_public_ip" "branch_app_vm" {
  name                = "${var.resource_prefix}-branch-app-vm-ip"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = merge(var.common_tags, {
    Purpose = "Branch Application VM"
  })
}

# Network Interfaces for Branch FTDv
resource "azurerm_network_interface" "branch_ftdv_mgmt" {
  name                = "${var.resource_prefix}-branch-ftdv-nic0"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "management"
    subnet_id                     = azurerm_subnet.branch_management.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.branch_ftdv_management_ip
    public_ip_address_id          = azurerm_public_ip.branch_ftdv_mgmt.id
  }
}

resource "azurerm_network_interface" "branch_ftdv_outside" {
  name                  = "${var.resource_prefix}-branch-ftdv-nic1"
  location              = azurerm_resource_group.branch.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "outside"
    subnet_id                     = azurerm_subnet.branch_outside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.branch_ftdv_outside_ip
    public_ip_address_id          = azurerm_public_ip.branch_ftdv_outside.id
  }
}

resource "azurerm_network_interface" "branch_ftdv_inside" {
  name                  = "${var.resource_prefix}-branch-ftdv-nic2"
  location              = azurerm_resource_group.branch.location
  resource_group_name   = azurerm_resource_group.main.name
  tags                  = var.common_tags
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "inside"
    subnet_id                     = azurerm_subnet.branch_inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.branch_ftdv_inside_ip
  }
}

# Branch FTDv Virtual Machine
resource "azurerm_virtual_machine" "branch_ftdv" {
  name                = "${var.resource_prefix}-branch-ftd76"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  vm_size             = var.ftdv_vm_size
  tags = merge(var.common_tags, {
    Purpose = "Branch FTDv Firewall"
    Site    = "Branch"
  })

  # NIC ordering is critical: nic0=mgmt, nic1=outside, nic2=inside
  primary_network_interface_id = azurerm_network_interface.branch_ftdv_mgmt.id
  network_interface_ids = [
    azurerm_network_interface.branch_ftdv_mgmt.id,
    azurerm_network_interface.branch_ftdv_outside.id,
    azurerm_network_interface.branch_ftdv_inside.id,
  ]

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
    name              = "${var.resource_prefix}-branch-ftdv-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.resource_prefix}-branch-ftd76"
    admin_username = var.ftdv_admin_username
    admin_password = var.ftdv_admin_password
    custom_data = base64encode(templatefile("${path.module}/userdata/ftd_userdata.tftpl", {
      admin_password = var.ftdv_admin_password
      hostname       = "${var.resource_prefix}-branch-ftd76"
    }))
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = data.azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }
}

# Network Interface for Branch Application VM
resource "azurerm_network_interface" "branch_app_vm" {
  name                = "${var.resource_prefix}-branch-app-vm-nic"
  location            = azurerm_resource_group.branch.location
  resource_group_name = azurerm_resource_group.branch.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.branch_app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.branch_app_vm_ip
    public_ip_address_id          = azurerm_public_ip.branch_app_vm.id
  }
}

# Branch Application VM
resource "azurerm_linux_virtual_machine" "branch_app_vm" {
  name                            = "${var.resource_prefix}-branch-app"
  location                        = azurerm_resource_group.branch.location
  resource_group_name             = azurerm_resource_group.branch.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "Branch Application VM"
    Site    = "Branch"
  })

  network_interface_ids = [
    azurerm_network_interface.branch_app_vm.id,
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
  - nginx
  - openssl

write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
      <head>
          <title>Branch Application Server</title>
          <style>
              body { font-family: Arial; margin: 40px; background: #f5f5f5; }
              .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              h1 { color: #e91e63; }
              .info { background: #fce4ec; padding: 15px; margin: 10px 0; border-left: 4px solid #e91e63; }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>🏢 Branch Site Application Server</h1>
              <div class="info">
                  <strong>Branch Network</strong><br>
                  VNet CIDR: 192.168.0.0/16<br>
                  Subnet: 192.168.102.0/24<br>
                  IP Address: 192.168.102.102<br>
                  Protected by: Branch FTDv Firewall
              </div>
          </div>
      </body>
      </html>
  
  - path: /etc/motd
    content: |
      ╔══════════════════════════════════════╗
      ║   BRANCH SITE - Application VM      ║
      ║   IP: 192.168.102.102                ║
      ╚══════════════════════════════════════╝

runcmd:
  # Generate self-signed SSL certificate
  - mkdir -p /etc/nginx/ssl
  - openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx-selfsigned.key -out /etc/nginx/ssl/nginx-selfsigned.crt -subj "/C=US/ST=California/L=San Jose/O=Cisco/OU=Security/CN=branch-app.local"
  - openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
  # Configure Nginx for HTTPS
  - |
    cat > /etc/nginx/sites-available/default <<'NGINXCONF'
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        return 301 https://\$host\$request_uri;
    }
    
    server {
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;
        
        ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;
        ssl_dhparam /etc/nginx/ssl/dhparam.pem;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_session_timeout 10m;
        ssl_session_cache shared:SSL:10m;
        
        root /var/www/html;
        index index.html;
        server_name _;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
    }
    NGINXCONF
  - systemctl enable nginx
  - systemctl start nginx
  - chown -R www-data:www-data /var/www/html
  - chmod -R 755 /var/www/html
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
  - echo "ubuntu:Cisco@123" | chpasswd
  - systemctl restart sshd
  - echo "Branch application VM setup complete" > /var/log/bootstrap.log
EOF
  )
}
