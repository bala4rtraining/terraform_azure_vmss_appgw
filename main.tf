# ----------------------------------------------------------------
# Azure Virtual Machione Scale Set with Application Gateway and
# Jump host for SSH access
#
# Geoff Kendal <Geoff@squiggle.org>  //  Feb 2018
# ----------------------------------------------------------------


# ------------------- Network Resources -------------------------

resource "azurerm_resource_group" "vmss" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vmss" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["${var.address_space}"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
}

resource "azurerm_subnet" "vmss" {
  name                 = "${var.resource_group_name}-vmss-subnet"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  virtual_network_name = "${azurerm_virtual_network.vmss.name}"
  address_prefix       = "${var.subnet_vmss}"
}

resource "azurerm_subnet" "gateway" {
  name                 = "${var.resource_group_name}-ag-subnet"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  virtual_network_name = "${azurerm_virtual_network.vmss.name}"
  address_prefix       = "${var.subnet_ag}"
}

resource "azurerm_public_ip" "vmss" {
  name                         = "${var.resource_group_name}-web-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.vmss.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${azurerm_resource_group.vmss.name}"
}

resource "azurerm_public_ip" "jumphost" {
  name                         = "${var.resource_group_name}-jumphost-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.vmss.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${azurerm_resource_group.vmss.name}-jumphost"
}


# ------------------- Application Gateway -------------------------


resource "azurerm_application_gateway" "vmss" {
  name                = "${var.resource_group_name}-ag"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  location            = "${var.location}"

  sku {
    name     = "${var.ag_name}"
    tier     = "Standard"
    capacity = "${var.ag_count}"
  }

  gateway_ip_configuration {
      name      = "${var.resource_group_name}-ag-ipconf"
      subnet_id = "${azurerm_virtual_network.vmss.id}/subnets/${azurerm_subnet.gateway.name}"
  }

  frontend_port {
      name = "${var.resource_group_name}-ag-feport"
      port = 80
  }

  frontend_ip_configuration {
      name                 = "${var.resource_group_name}-ag-feip"  
      public_ip_address_id = "${azurerm_public_ip.vmss.id}"
  }

  backend_address_pool {
      name = "${var.resource_group_name}-ag-beap"
  }

  backend_http_settings {
      name                  = "${var.resource_group_name}-ag-behttp"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 10
  }

  http_listener {
        name                           = "${var.resource_group_name}-ag-httplistener"
        frontend_ip_configuration_name = "${var.resource_group_name}-ag-feip"
        frontend_port_name             = "${var.resource_group_name}-ag-feport"
        protocol                       = "Http"
  }

  request_routing_rule {
          name                       = "${var.resource_group_name}-awg-rqrt"
          rule_type                  = "Basic"
          http_listener_name         = "${var.resource_group_name}-ag-httplistener"
          backend_address_pool_name  = "${var.resource_group_name}-ag-beap"
          backend_http_settings_name = "${var.resource_group_name}-ag-behttp"
  }
}


# ------------------- Virtual Machine Scale Set -------------------------


resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${var.resource_group_name}-web"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "${var.vmss_type}"
    tier     = "Standard"
    capacity = "${var.vmss_count}"
  }

  storage_profile_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name_prefix = "${var.resource_group_name}-web"
    admin_username       = "${var.vm_username}"
    admin_password       = "${var.vm_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "DeafultNetworkProfile"
    primary = true

    ip_configuration {
      name      = "IPConfiguration"
      subnet_id = "${azurerm_subnet.vmss.id}"
    }
  }

  extension { 
    name                 = "vmssextension"
    publisher            = "Microsoft.OSTCExtensions"
    type                 = "CustomScriptForLinux"
    type_handler_version = "1.2"
    settings = <<SETTINGS
    {
      "fileUris": ["${azurerm_storage_blob.bootstrap.url}"],
      "commandToExecute": "bash bootstrap.sh ${azurerm_storage_account.data.name} ${azurerm_storage_account.data.primary_access_key} ${azurerm_storage_share.data.name}"
    }
    SETTINGS
  }
}


# ------------------------- Jump Host -------------------------------


resource "azurerm_network_interface" "jumphost" {
  name                = "${var.resource_group_name}-jumphost-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${azurerm_subnet.vmss.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumphost.id}"
  }
}

resource "azurerm_virtual_machine_extension" "jumphost" {
  name                 = "${var.resource_group_name}-jumphost-extension"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  virtual_machine_name = "${azurerm_virtual_machine.jumphost.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"

  settings = <<SETTINGS
  {
    "fileUris": ["${azurerm_storage_blob.bootstrap.url}"],
    "commandToExecute": "bash bootstrap.sh ${azurerm_storage_account.data.name} ${azurerm_storage_account.data.primary_access_key} ${azurerm_storage_share.data.name}"
  }
  SETTINGS
}

resource "azurerm_virtual_machine" "jumphost" {
  name                          = "${var.resource_group_name}-jumphost"
  location                      = "${var.location}"
  resource_group_name           = "${azurerm_resource_group.vmss.name}"
  network_interface_ids         = ["${azurerm_network_interface.jumphost.id}"]
  vm_size                       = "Standard_B1ms"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.3"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.resource_group_name}-jumphost-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumphost"
    admin_username = "${var.vm_username}"
    admin_password = "${var.vm_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


# ------------------------- Storage -------------------------------

resource "azurerm_storage_account" "data" {
  name                     = "${var.resource_group_name}"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.vmss.name}"
  account_tier             = "Standard"
  account_replication_type = "${var.data_replication}"
}

resource "azurerm_storage_share" "data" {
  name                 = "web-data"
  resource_group_name  = "${azurerm_resource_group.vmss.name}"
  storage_account_name = "${azurerm_storage_account.data.name}"
  quota                = "${var.data_quota}"
}

resource "azurerm_storage_container" "data" {
  name                  = "provisioning"
  resource_group_name   = "${azurerm_resource_group.vmss.name}"
  storage_account_name  = "${azurerm_storage_account.data.name}"
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "bootstrap" {
  name                   = "bootstrap.sh"
  resource_group_name    = "${azurerm_resource_group.vmss.name}"
  storage_account_name   = "${azurerm_storage_account.data.name}"
  storage_container_name = "${azurerm_storage_container.data.name}"
  type                   = "block"
  size                   = 5120
  source                 = "files/bootstrap.sh"
}


# ------------------------- Database -------------------------------

resource "azurerm_mysql_server" "db" {
  name                = "${var.resource_group_name}-db"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.vmss.name}"

  sku {
    name = "MYSQLB50"
    capacity = 50
    tier = "Basic"
  }

  administrator_login = "${var.db_user}"
  administrator_login_password = "${var.db_pass}"
  version = "5.7"
  storage_mb = "${var.db_quota}"
  ssl_enforcement = "Disabled"
}

resource "azurerm_mysql_database" "db" {
  name                = "${var.resource_group_name}db"
  resource_group_name = "${azurerm_resource_group.vmss.name}"
  server_name         = "${azurerm_mysql_server.db.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
