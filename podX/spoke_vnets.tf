# Spoke VNets Infrastructure
# Spoke1 and Spoke2 VNets with test VMs for validating traffic flow through security inspection

# Spoke1 Virtual Network
resource "azurerm_virtual_network" "spoke1" {
  name                = "${var.resource_prefix}-spoke1-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.spoke1_vnet_cidr]
  tags = merge(var.common_tags, {
    Spoke = "Spoke1"
  })
}

# Spoke1 Web Subnet
resource "azurerm_subnet" "spoke1_web" {
  name                 = "${var.resource_prefix}-spoke1-web-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke1_web_subnet_cidr]
}

# Spoke1 App Subnet
resource "azurerm_subnet" "spoke1_app" {
  name                 = "${var.resource_prefix}-spoke1-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke1_app_subnet_cidr]
}

# Spoke1 DB Subnet
resource "azurerm_subnet" "spoke1_db" {
  name                 = "${var.resource_prefix}-spoke1-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke1_db_subnet_cidr]
}

# Spoke2 Virtual Network
resource "azurerm_virtual_network" "spoke2" {
  name                = "${var.resource_prefix}-spoke2-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.spoke2_vnet_cidr]
  tags = merge(var.common_tags, {
    Spoke = "Spoke2"
  })
}

# Spoke2 App Subnet
resource "azurerm_subnet" "spoke2_app" {
  name                 = "${var.resource_prefix}-spoke2-app-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = [var.spoke2_app_subnet_cidr]
}

# Network Security Group for Spoke Subnets
resource "azurerm_network_security_group" "spoke1_private" {
  name                = "${var.resource_prefix}-spoke1-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  # Allow HTTP from internet
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow HTTPS from internet
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow SSH from 151.0.0.0/8
  security_rule {
    name                       = "AllowSSH"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "151.0.0.0/8"
    destination_address_prefix = "*"
  }

  # Allow all from trusted networks
  security_rule {
    name                       = "AllowTrustedNetworks"
    priority                   = 120
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

# Network Security Group for Spoke2 Subnet
resource "azurerm_network_security_group" "spoke2_private" {
  name                = "${var.resource_prefix}-spoke2-private-nsg"
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

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "spoke1_web" {
  subnet_id                 = azurerm_subnet.spoke1_web.id
  network_security_group_id = azurerm_network_security_group.spoke1_private.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1_app" {
  subnet_id                 = azurerm_subnet.spoke1_app.id
  network_security_group_id = azurerm_network_security_group.spoke1_private.id
}

resource "azurerm_subnet_network_security_group_association" "spoke1_db" {
  subnet_id                 = azurerm_subnet.spoke1_db.id
  network_security_group_id = azurerm_network_security_group.spoke1_private.id
}

resource "azurerm_subnet_network_security_group_association" "spoke2_app" {
  subnet_id                 = azurerm_subnet.spoke2_app.id
  network_security_group_id = azurerm_network_security_group.spoke2_private.id
}

# Public IP for Web Server
resource "azurerm_public_ip" "spoke1_web" {
  name                = "${var.resource_prefix}-spoke1-web-nic-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = merge(var.common_tags, {
    Purpose = "Web Server Public Access"
  })
}

# Network Interfaces for Spoke1 VMs (Web, App, DB)
resource "azurerm_network_interface" "spoke1_web" {
  name                = "${var.resource_prefix}-spoke1-web-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_web.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.101.101.100"
    public_ip_address_id          = azurerm_public_ip.spoke1_web.id
  }
}

resource "azurerm_network_interface" "spoke1_app" {
  name                = "${var.resource_prefix}-spoke1-app-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.101.102.100"
  }
}

resource "azurerm_network_interface" "spoke1_db" {
  name                = "${var.resource_prefix}-spoke1-db-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_db.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.101.103.100"
  }
}

# Network Interfaces for Spoke2 VMs
resource "azurerm_network_interface" "spoke2_app2a" {
  name                = "${var.resource_prefix}-spoke2-app2a-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.102.102.101"
  }
}

resource "azurerm_network_interface" "spoke2_app2b" {
  name                = "${var.resource_prefix}-spoke2-app2b-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.102.102.102"
  }
}

# Spoke1 Web VM
resource "azurerm_linux_virtual_machine" "spoke1_web" {
  name                            = "${var.resource_prefix}-spoke1-web"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "Web Server - Spoke1"
    Tier    = "Web"
  })

  network_interface_ids = [
    azurerm_network_interface.spoke1_web.id,
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

  # Install nginx web server with PHP
  custom_data = base64encode(<<-EOF
#!/bin/bash
set -e

# Update and install packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y net-tools vim iputils-ping sshpass curl wget tcpdump nmap htop
apt-get install -y nginx php-fpm php-mysql php-curl php-json openssl

# Generate self-signed SSL certificate
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx-selfsigned.key -out /etc/nginx/ssl/nginx-selfsigned.crt -subj "/C=US/ST=California/L=San Jose/O=Cisco/OU=Security/CN=spoke-web.local"
openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

# Configure Nginx for PHP with HTTPS
cat > /etc/nginx/sites-available/default <<'NGINX'
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
    index index.php index.html;
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
NGINX

systemctl restart nginx
systemctl enable nginx

# Create web application
cat > /var/www/html/index.php <<'HTML'
<!DOCTYPE html>
<html>
<head>
<title>3-Tier Application Demo</title>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
    .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 16px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); overflow: hidden; }
    .header { background: linear-gradient(135deg, #049fd9 0%, #0277bd 100%); color: white; padding: 30px; text-align: center; }
    .header h1 { font-size: 2.5em; margin-bottom: 10px; }
    .header p { opacity: 0.9; font-size: 1.1em; }
    .content { padding: 40px; }
    .architecture { display: flex; justify-content: space-between; margin: 40px 0; flex-wrap: wrap; gap: 20px; }
    .tier { flex: 1; min-width: 280px; background: #f8f9fa; padding: 25px; border-radius: 12px; text-align: center; border: 3px solid #e0e0e0; position: relative; }
    .tier.active { border-color: #049fd9; box-shadow: 0 8px 24px rgba(4,159,217,0.2); }
    .tier h3 { color: #333; margin-bottom: 15px; font-size: 1.4em; }
    .tier .icon { font-size: 3em; margin-bottom: 15px; }
    .tier .details { font-size: 0.9em; color: #666; line-height: 1.8; text-align: left; }
    .tier .status { display: inline-block; padding: 6px 12px; border-radius: 20px; font-size: 0.85em; font-weight: bold; margin-top: 10px; }
    .status.online { background: #d4edda; color: #155724; }
    .status.offline { background: #f8d7da; color: #721c24; }
    .arrow { font-size: 2em; color: #049fd9; align-self: center; }
    .buttons { display: flex; gap: 15px; margin: 30px 0; flex-wrap: wrap; justify-content: center; }
    button { background: linear-gradient(135deg, #049fd9 0%, #0277bd 100%); color: white; padding: 15px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 1em; font-weight: bold; transition: all 0.3s; box-shadow: 0 4px 12px rgba(4,159,217,0.3); }
    button:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(4,159,217,0.4); }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    #result { margin-top: 30px; padding: 25px; border-radius: 12px; display: none; }
    #result.success { background: #d4edda; border-left: 5px solid #28a745; }
    #result.error { background: #f8d7da; border-left: 5px solid #dc3545; }
    #result.info { background: #d1ecf1; border-left: 5px solid #17a2b8; }
    .loading { display: inline-block; width: 20px; height: 20px; border: 3px solid #fff; border-radius: 50%; border-top-color: transparent; animation: spin 1s linear infinite; margin-left: 10px; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .flow-indicator { height: 4px; background: #049fd9; margin: 20px 0; border-radius: 2px; animation: pulse 2s ease-in-out infinite; }
    @keyframes pulse { 0%, 100% { opacity: 0.4; } 50% { opacity: 1; } }
    pre { background: #2d2d2d; color: #f8f8f2; padding: 20px; border-radius: 8px; overflow-x: auto; font-size: 0.9em; line-height: 1.6; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>🚀 3-Tier Application Architecture Demo</h1>
        <p>Interactive demonstration of Web → App → Database tier communication</p>
    </div>
    <div class="content">
        <div class="architecture">
            <div class="tier" id="web-tier">
                <div class="icon">🌐</div>
                <h3>Web Tier</h3>
                <div class="details">
                    <strong>Server:</strong> <?php echo gethostname(); ?><br>
                    <strong>IP:</strong> <?php echo $_SERVER['SERVER_ADDR']; ?><br>
                    <strong>Stack:</strong> Nginx + PHP 8.1
                </div>
                <span class="status online">● ONLINE</span>
            </div>
            <div class="arrow">→</div>
            <div class="tier" id="app-tier">
                <div class="icon">⚙️</div>
                <h3>App Tier</h3>
                <div class="details">
                    <strong>Server:</strong> pod1-spoke1-app<br>
                    <strong>IP:</strong> 10.101.102.100<br>
                    <strong>Stack:</strong> Node.js API
                </div>
                <span class="status" id="app-status">● UNKNOWN</span>
            </div>
            <div class="arrow">→</div>
            <div class="tier" id="db-tier">
                <div class="icon">🗄️</div>
                <h3>Database Tier</h3>
                <div class="details">
                    <strong>Server:</strong> pod1-spoke1-db<br>
                    <strong>IP:</strong> 10.101.103.100<br>
                    <strong>Stack:</strong> MySQL 8.0
                </div>
                <span class="status" id="db-status">● UNKNOWN</span>
            </div>
        </div>
        
        <div class="buttons">
            <button onclick="testAppTier()">📡 Test App Tier Connection</button>
            <button onclick="testDatabase()">💾 Test Database Query</button>
            <button onclick="testFullStack()">🔄 Test Full Stack Flow</button>
            <button onclick="getUsers()">👥 Fetch User Data</button>
        </div>
        
        <div id="result"></div>
    </div>
</div>

<script>
    function showResult(message, type = 'info') {
        const result = document.getElementById('result');
        result.innerHTML = message;
        result.className = type;
        result.style.display = 'block';
    }

    function showLoading(button) {
        button.disabled = true;
        button.innerHTML += '<span class="loading"></span>';
    }

    function hideLoading(button, originalText) {
        button.disabled = false;
        button.innerHTML = originalText;
    }

    async function testAppTier() {
        const btn = event.target;
        const originalText = btn.innerHTML;
        showLoading(btn);
        document.getElementById('app-tier').classList.add('active');
        
        showResult('<h3>🔄 Testing App Tier Connection...</h3><div class="flow-indicator"></div><p>Connecting to 10.101.102.100:3000</p>', 'info');
        
        try {
            const response = await fetch('/api.php?action=test_app');
            if (!response.ok) throw new Error('HTTP error! status: ' + response.status);
            const data = await response.json();
            
            if (data.status === 'success') {
                document.getElementById('app-status').className = 'status online';
                document.getElementById('app-status').textContent = '● ONLINE';
                showResult(\`
                    <h3>✅ App Tier Connected Successfully!</h3>
                    <div class="flow-indicator"></div>
                    <p><strong>Data Flow:</strong> Web Tier (<?php echo $_SERVER['SERVER_ADDR']; ?>) → App Tier (10.101.102.100:3000)</p>
                    <h4>App Tier Response:</h4>
                    <pre>\$${'{'}JSON.stringify(data.app_response, null, 2)}</pre>
                \`, 'success');
            } else {
                document.getElementById('app-status').className = 'status offline';
                document.getElementById('app-status').textContent = '● OFFLINE';
                showResult('<h3>❌ Failed to connect to App Tier</h3><p>' + data.message + '</p><p>The Node.js application server may not be running on 10.101.102.100:3000</p>', 'error');
            }
        } catch (error) {
            document.getElementById('app-status').className = 'status offline';
            document.getElementById('app-status').textContent = '● OFFLINE';
            showResult('<h3>❌ Connection Error</h3><p>' + error.message + '</p><p>Cannot communicate with App Tier API</p>', 'error');
        }
        
        hideLoading(btn, originalText);
        document.getElementById('app-tier').classList.remove('active');
    }

    async function testDatabase() {
        const btn = event.target;
        const originalText = btn.innerHTML;
        showLoading(btn);
        document.getElementById('app-tier').classList.add('active');
        document.getElementById('db-tier').classList.add('active');
        
        showResult('<h3>🔄 Testing Database Connection...</h3><div class="flow-indicator"></div><p>Web Tier → App Tier (10.101.102.100) → Database (10.101.103.100)</p>', 'info');
        
        try {
            const response = await fetch('/api.php?action=test_db');
            if (!response.ok) throw new Error('HTTP error! status: ' + response.status);
            const data = await response.json();
            
            if (data.status === 'success') {
                document.getElementById('app-status').className = 'status online';
                document.getElementById('app-status').textContent = '● ONLINE';
                document.getElementById('db-status').className = 'status online';
                document.getElementById('db-status').textContent = '● ONLINE';
                showResult(\`
                    <h3>✅ Database Connected Successfully!</h3>
                    <div class="flow-indicator"></div>
                    <p><strong>Data Flow:</strong> Web Tier (<?php echo $_SERVER['SERVER_ADDR']; ?>) → App Tier (10.101.102.100:3000) → MySQL Database (10.101.103.100:3306)</p>
                    <h4>Database Query Response:</h4>
                    <pre>\$${'{'}JSON.stringify(data.db_response, null, 2)}</pre>
                \`, 'success');
            } else {
                document.getElementById('db-status').className = 'status offline';
                document.getElementById('db-status').textContent = '● OFFLINE';
                showResult('<h3>❌ Database Connection Failed</h3><p>' + data.message + '</p><p>Check if MySQL is running on 10.101.103.100 and App Tier can reach it</p>', 'error');
            }
        } catch (error) {
            document.getElementById('db-status').className = 'status offline';
            document.getElementById('db-status').textContent = '● OFFLINE';
            showResult('<h3>❌ Connection Error</h3><p>' + error.message + '</p><p>Cannot query database through App Tier</p>', 'error');
        }
        
        hideLoading(btn, originalText);
        document.getElementById('app-tier').classList.remove('active');
        document.getElementById('db-tier').classList.remove('active');
    }

    async function testFullStack() {
        const btn = event.target;
        const originalText = btn.innerHTML;
        showLoading(btn);
        document.getElementById('app-tier').classList.add('active');
        document.getElementById('db-tier').classList.add('active');
        
        showResult('<h3>🔄 Testing Full Stack...</h3><div class="flow-indicator"></div><p>Web Tier → App Tier → Database Tier → Response</p>', 'info');
        
        try {
            const response = await fetch('/api.php?action=full_stack');
            if (!response.ok) throw new Error('HTTP error! status: ' + response.status);
            const data = await response.json();
            
            if (data.status === 'success') {
                document.getElementById('app-status').className = 'status online';
                document.getElementById('app-status').textContent = '● ONLINE';
                document.getElementById('db-status').className = 'status online';
                document.getElementById('db-status').textContent = '● ONLINE';
                
                showResult(\`
                    <h3>✅ Full Stack Test Successful!</h3>
                    <div class="flow-indicator"></div>
                    <p><strong>Complete Data Flow Verified:</strong></p>
                    <h4>1️⃣ Web Tier (You are here)</h4>
                    <pre>Server: <?php echo gethostname(); ?>\nIP: <?php echo $_SERVER['SERVER_ADDR']; ?>\nStack: Nginx + PHP 8.1</pre>
                    <h4>2️⃣ App Tier Response (10.101.102.100:3000)</h4>
                    <pre>\$${'{'}JSON.stringify(data.app_response, null, 2)}</pre>
                    <h4>3️⃣ Database Response (10.101.103.100:3306)</h4>
                    <pre>\$${'{'}JSON.stringify(data.db_response, null, 2)}</pre>
                    <p style="margin-top:15px; color:#155724;">✅ All three tiers are communicating successfully!</p>
                \`, 'success');
            } else {
                showResult('<h3>❌ Full Stack Test Failed</h3><p>' + data.message + '</p><p>One or more tiers are not responding correctly</p>', 'error');
            }
        } catch (error) {
            showResult('<h3>❌ Connection Error</h3><p>' + error.message + '</p><p>Full stack communication failed</p>', 'error');
        }
        
        hideLoading(btn, originalText);
        document.getElementById('app-tier').classList.remove('active');
        document.getElementById('db-tier').classList.remove('active');
    }

    async function getUsers() {
        const btn = event.target;
        const originalText = btn.innerHTML;
        showLoading(btn);
        document.getElementById('app-tier').classList.add('active');
        document.getElementById('db-tier').classList.add('active');
        
        showResult('<h3>🔄 Fetching User Data...</h3><div class="flow-indicator"></div><p>Querying database through App Tier...</p>', 'info');
        
        try {
            const response = await fetch('/api.php?action=get_users');
            if (!response.ok) throw new Error('HTTP error! status: ' + response.status);
            const data = await response.json();
            
            if (data.status === 'success') {
                document.getElementById('app-status').className = 'status online';
                document.getElementById('app-status').textContent = '● ONLINE';
                document.getElementById('db-status').className = 'status online';
                document.getElementById('db-status').textContent = '● ONLINE';
                
                const users = data.users;
                let userTable = '<table style="width:100%; border-collapse: collapse; margin-top: 15px;"><tr style="background:#049fd9; color:white;"><th style="padding:10px; text-align:left;">ID</th><th style="padding:10px; text-align:left;">Username</th><th style="padding:10px; text-align:left;">Email</th><th style="padding:10px; text-align:left;">Created</th></tr>';
                users.forEach(user => {
                    userTable += \`<tr style="border-bottom:1px solid #ddd;"><td style="padding:10px;">\$${'{'}user.id}</td><td style="padding:10px;">\$${'{'}user.username}</td><td style="padding:10px;">\$${'{'}user.email}</td><td style="padding:10px;">\$${'{'}user.created_at}</td></tr>\`;
                });
                userTable += '</table>';
                
                showResult(\`
                    <h3>✅ User Data Retrieved Successfully!</h3>
                    <div class="flow-indicator"></div>
                    <p><strong>Data Flow:</strong> Web Tier → App Tier (10.101.102.100) → Database (10.101.103.100) → demo_db.users</p>
                    <p><strong>Total Users:</strong> \$${'{'}users.length}</p>
                    \$${'{'}userTable}
                \`, 'success');
            } else {
                showResult('<h3>❌ Failed to fetch users</h3><p>' + data.message + '</p><p>Database query failed or table does not exist</p>', 'error');
            }
        } catch (error) {
            showResult('<h3>❌ Connection Error</h3><p>' + error.message + '</p><p>Cannot retrieve data from database</p>', 'error');
        }
        
        hideLoading(btn, originalText);
        document.getElementById('app-tier').classList.remove('active');
        document.getElementById('db-tier').classList.remove('active');
    }

    // Test app tier on page load
    window.onload = () => {
        setTimeout(() => {
            fetch('/api.php?action=test_app')
                .then(r => {
                    if (!r.ok) throw new Error('HTTP ' + r.status);
                    return r.json();
                })
                .then(data => {
                    if (data.status === 'success') {
                        document.getElementById('app-status').className = 'status online';
                        document.getElementById('app-status').textContent = '● ONLINE';
                    } else {
                        document.getElementById('app-status').className = 'status offline';
                        document.getElementById('app-status').textContent = '● OFFLINE';
                    }
                })
                .catch(() => {
                    document.getElementById('app-status').className = 'status offline';
                    document.getElementById('app-status').textContent = '● OFFLINE';
                });
        }, 1000);
    };
</script>
</body>
</html>
HTML

cat > /var/www/html/api.php <<'PHP'
<?php
\$app_server = "10.101.102.100";
\$app_port = 3000;

header('Content-Type: application/json');

\$action = isset(\$_GET['action']) ? \$_GET['action'] : '';

switch (\$action) {
case 'test_app':
    \$response = @file_get_contents("http://" . \$app_server . ":" . \$app_port . "/api/status");
    if (\$response !== false) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Connected to App Tier',
            'app_response' => json_decode(\$response)
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Cannot reach App Tier']);
    }
    break;
    
case 'test_db':
    \$response = @file_get_contents("http://" . \$app_server . ":" . \$app_port . "/api/db-test");
    if (\$response !== false) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Database connected',
            'db_response' => json_decode(\$response)
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Cannot reach database through App Tier']);
    }
    break;
    
case 'full_stack':
    \$app_response = @file_get_contents("http://" . \$app_server . ":" . \$app_port . "/api/status");
    \$db_response = @file_get_contents("http://" . \$app_server . ":" . \$app_port . "/api/db-test");
    
    if (\$app_response !== false && \$db_response !== false) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Full stack operational',
            'app_response' => json_decode(\$app_response),
            'db_response' => json_decode(\$db_response)
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Full stack test failed']);
    }
    break;
    
case 'get_users':
    \$response = @file_get_contents("http://" . \$app_server . ":" . \$app_port . "/api/users");
    if (\$response !== false) {
        \$data = json_decode(\$response, true);
        echo json_encode([
            'status' => 'success',
            'users' => \$data['users']
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Cannot fetch users']);
    }
    break;
    
default:
    echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
}
?>
PHP
      
      # Set permissions
      chown -R www-data:www-data /var/www/html
      chmod -R 755 /var/www/html
      
      # SSH configuration
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
      # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
      echo "ubuntu:Cisco@123" | chpasswd
      systemctl restart sshd
      
      # Create motd
      cat > /etc/motd <<'MOTD'
      ╔══════════════════════════════════════╗
      ║   WEB TIER - 3-Tier Demo App        ║
      ║   Nginx + PHP-FPM                    ║
      ╚══════════════════════════════════════╝
      MOTD
      
      echo "Web tier setup complete" > /var/log/bootstrap.log
EOF
  )
}

# Spoke1 App VM
resource "azurerm_linux_virtual_machine" "spoke1_app" {
  name                            = "${var.resource_prefix}-spoke1-app"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "App Server - Spoke1"
    Tier    = "App"
  })

  network_interface_ids = [
    azurerm_network_interface.spoke1_app.id,
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

  # Install Node.js application server with Python
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
  - python3
  - python3-pip
  - python3-venv

write_files:
  - path: /tmp/setup-app.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      # Install Node.js
      curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
      apt-get install -y nodejs
      
      # Install Python dependencies
      pip3 install flask requests mysql-connector-python
      
      # Create Node.js API application
      mkdir -p /opt/app
      cat > /opt/app/server.js <<'NODEJS'
const http = require('http');
const mysql = require('mysql');

const DB_HOST = '10.101.103.100'; // Database tier IP
const PORT = 3000;

// Database connection pool
const pool = mysql.createPool({
connectionLimit: 10,
host: DB_HOST,
user: 'appuser',
password: 'AppPass123!',
database: 'demo_db'
});

const server = http.createServer((req, res) => {
res.setHeader('Content-Type', 'application/json');
res.setHeader('Access-Control-Allow-Origin', '*');

if (req.url === '/api/status') {
    res.writeHead(200);
    res.end(JSON.stringify({
        status: 'healthy',
        tier: 'application',
        hostname: require('os').hostname(),
        timestamp: new Date().toISOString(),
        node_version: process.version,
        database_host: DB_HOST
    }));
} 
else if (req.url === '/api/db-test') {
    pool.query('SELECT COUNT(*) as count FROM users', (err, results) => {
        if (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ 
                status: 'error',
                error: 'Database error', 
                details: err.message 
            }));
        } else {
            res.writeHead(200);
            res.end(JSON.stringify({ 
                status: 'connected',
                database: DB_HOST,
                user_count: results[0].count,
                timestamp: new Date().toISOString()
            }));
        }
    });
}
else if (req.url === '/api/users') {
    pool.query('SELECT id, username, email, created_at FROM users ORDER BY id LIMIT 10', (err, results) => {
        if (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ 
                status: 'error',
                error: 'Database error', 
                details: err.message 
            }));
        } else {
            res.writeHead(200);
            res.end(JSON.stringify({ 
                status: 'success',
                users: results,
                count: results.length,
                timestamp: new Date().toISOString()
            }));
        }
    });
}
else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
}
});

server.listen(PORT, '0.0.0.0', () => {
console.log('App server running on port ' + PORT);
});
      NODEJS
      
      # Install Node.js dependencies
      cd /opt/app
      npm init -y
      npm install mysql
      
      # Create systemd service
      cat > /etc/systemd/system/app-server.service <<'SERVICE'
      [Unit]
      Description=Node.js Application Server
      After=network.target
      
      [Service]
      Type=simple
      User=root
      WorkingDirectory=/opt/app
      ExecStart=/usr/bin/node /opt/app/server.js
      Restart=always
      RestartSec=10
      
      [Install]
      WantedBy=multi-user.target
      SERVICE
      
      systemctl daemon-reload
      systemctl enable app-server
      systemctl start app-server
      
      # SSH configuration
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
      # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
      echo "ubuntu:Cisco@123" | chpasswd
      systemctl restart sshd
      
      # Create motd
      cat > /etc/motd <<'MOTD'
      ╔══════════════════════════════════════╗
      ║   APP TIER - 3-Tier Demo App        ║
      ║   Node.js API Server + Python        ║
      ╚══════════════════════════════════════╝
      MOTD
      
      echo "App tier setup complete" > /var/log/bootstrap.log

runcmd:
  - /tmp/setup-app.sh
EOF
  )
}

# Spoke1 DB VM
resource "azurerm_linux_virtual_machine" "spoke1_db" {
  name                            = "${var.resource_prefix}-spoke1-db"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "Database Server - Spoke1"
    Tier    = "Database"
  })

  network_interface_ids = [
    azurerm_network_interface.spoke1_db.id,
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

  # Install MySQL database server
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
  - mysql-server
  - mysql-client

write_files:
  - path: /tmp/setup-db.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      # Configure MySQL for remote connections
      sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
      systemctl restart mysql
      
      # Wait for MySQL to start
      sleep 10
      
      # Create database and user
      mysql <<'MYSQL'
CREATE DATABASE IF NOT EXISTS demo_db;

CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'AppPass123!';
GRANT ALL PRIVILEGES ON demo_db.* TO 'appuser'@'%';

USE demo_db;

CREATE TABLE IF NOT EXISTS users (
id INT AUTO_INCREMENT PRIMARY KEY,
username VARCHAR(50) NOT NULL,
email VARCHAR(100),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT,
product VARCHAR(100),
amount DECIMAL(10,2),
order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Insert sample data
INSERT INTO users (username, email) VALUES 
('alice', 'alice@example.com'),
('bob', 'bob@example.com'),
('charlie', 'charlie@example.com');

INSERT INTO orders (user_id, product, amount) VALUES
(1, 'Laptop', 999.99),
(1, 'Mouse', 29.99),
(2, 'Keyboard', 79.99),
(3, 'Monitor', 299.99);

      FLUSH PRIVILEGES;
      MYSQL
      
      # SSH configuration
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
      # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
      echo "ubuntu:Cisco@123" | chpasswd
      systemctl restart sshd
      
      # Create motd
      cat > /etc/motd <<'MOTD'
      ╔══════════════════════════════════════╗
      ║   DATABASE TIER - 3-Tier Demo App   ║
      ║   MySQL 8.0 Database Server          ║
      ╚══════════════════════════════════════╝
      
      Database: demo_db
      Tables: users, orders
      Sample data loaded ✓
      MOTD
      
      echo "Database tier setup complete" > /var/log/bootstrap.log
      
      # Show database info
      mysql -e "SELECT TABLE_NAME, TABLE_ROWS FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'demo_db';" > /var/log/db_info.log

runcmd:
  - /tmp/setup-db.sh
EOF
  )
}

# Spoke2 App2a VM
resource "azurerm_linux_virtual_machine" "spoke2_app2a" {
  name                            = "${var.resource_prefix}-spoke2-app2a"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "Test VM Spoke2 App2a"
  })

  network_interface_ids = [
    azurerm_network_interface.spoke2_app2a.id,
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

  # Install basic networking tools
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

write_files:
  - path: /var/www/html/index.html
    content: |
      <h1>Spoke2 App2a VM</h1>
      <p>Private IP: PLACEHOLDER</p>
      <p>Hostname: PLACEHOLDER</p>

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
  - echo "ubuntu:Cisco@123" | chpasswd
  - systemctl restart sshd
  - echo "<h1>Spoke2 App2a VM</h1><p>Private IP:$(hostname -I | cut -d' ' -f1)</p><p>Hostname:$(hostname)</p>" > /var/www/html/index.html
EOF
  )
}

# Spoke2 App2b VM
resource "azurerm_linux_virtual_machine" "spoke2_app2b" {
  name                            = "${var.resource_prefix}-spoke2-app2b"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password
  tags = merge(var.common_tags, {
    Purpose = "App Server - Spoke2"
    Tier    = "App"
  })

  network_interface_ids = [
    azurerm_network_interface.spoke2_app2b.id,
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

  # Install basic application server tools
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

write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
      <head>
          <title>Spoke2 App Server</title>
          <style>
              body { font-family: Arial; margin: 40px; background: #f5f5f5; }
              .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              h1 { color: #1e88e5; }
              .info { background: #e3f2fd; padding: 15px; margin: 10px 0; border-left: 4px solid #1e88e5; }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>🔧 Spoke2 App2b Server</h1>
              <div class="info">
                  <strong>Application Tier</strong><br>
                  Location: Spoke2 VNet<br>
                  Role: Backend Application Processing<br>
                  Server: Nginx
              </div>
          </div>
      </body>
      </html>
  
  - path: /etc/motd
    content: |
      ╔══════════════════════════════════════╗
      ║   APP TIER - Spoke2 Application     ║
      ║   Nginx Application Server           ║
      ╚══════════════════════════════════════╝

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - chown -R www-data:www-data /var/www/html
  - chmod -R 755 /var/www/html
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  # ⚠️  LAB-ONLY CREDENTIAL — Do NOT use in production environments.
  - echo "ubuntu:Cisco@123" | chpasswd
  - systemctl restart sshd
  - echo "Spoke2 app tier setup complete" > /var/log/bootstrap.log
EOF
  )
}

# Route Tables for Spoke VNets to route traffic through Security VNet
# Spoke1 Route Table
# Route tables removed - to be configured via Azure Portal UI