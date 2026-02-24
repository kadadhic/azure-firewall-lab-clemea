# Resource Naming
resource_prefix = "podX"

# Azure Configuration
azure_region = "West Europe"

# FTDv Configuration
ftdv_admin_password = "<PASSWORD>"

# Test VM Configuration
admin_password = "<PASSWORD>" 
common_tags = {
  Environment = "dev"
  Project     = "podX-automation-azure"
  Owner       = "terraform"
}

# Security Configuration
trusted_networks = ["10.0.0.0/8"] // Add more networks in the list (separated by commas) that you want to allow access from. 
azure_subscription_id = "<ENTER_YOUR_SUBSCRIPTION_ID>" 
user_principal_name = "PodX@ciscodemo.onmicrosoft.com" // Replace this with the actual user principal name of the demo user in your Azure AD tenant.