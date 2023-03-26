terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.41.0"
    }
  }
  backend "azurerm" {
     subscription_id = "f87d8f4a-1113-4fec-82c4-c40bda2841db"
    tenant_id       = "a4dacaae-322d-49d4-91a1-1cdbbce883d0"
    resource_group_name = "zubrg"
    storage_account_name = "zubcontainer"
    container_name = "tfstate"
    access_key = "3KaODYc0BrJXuzjIZsN6glxCXo17MKM02Y2kTvzMW/NVX5If6OapjbwkssDzsJfnp41O7HTszsOe+AStt6wiOA=="
  }
    
  }


provider "azurerm" {
    features {}
    subscription_id = "f87d8f4a-1113-4fec-82c4-c40bda2841db"
    tenant_id       = "a4dacaae-322d-49d4-91a1-1cdbbce883d0"
    client_id       = "58f2673c-133f-4b18-b296-d086557c031e"
    client_secret   = "2pA8Q~GFAH3vLHzsMSoARctH47y5LmKJqawO9aiG"  
  
}

resource "azurerm_resource_group" "terraform-rg" {
  name     = var.rgname
  location = var.region
}
resource "azurerm_virtual_network" "terraform-rg-vnet" {
  name                = var.vnname
  location            = azurerm_resource_group.terraform-rg.location
  resource_group_name = azurerm_resource_group.terraform-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  
 tags = {
    environment = var.tag
  }
  
 
}
resource "azurerm_subnet" "subnet" {
  name                 = var.subnetname
  resource_group_name  = azurerm_resource_group.terraform-rg.name
  virtual_network_name = azurerm_virtual_network.terraform-rg-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}



 


resource "azurerm_network_security_group" "tfvm-nsg" {
  name                = "tfvm-nsg"
  location            = azurerm_resource_group.terraform-rg.location
  resource_group_name = azurerm_resource_group.terraform-rg.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.tag
  }
}

resource "azurerm_network_interface" "main" {
  name                = "tfvm001-nic"
  location            = azurerm_resource_group.terraform-rg.location
  resource_group_name = azurerm_resource_group.terraform-rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "tfvm001" {

 
  name                  = var.vmname
  location              = azurerm_resource_group.terraform-rg.location
  resource_group_name   = azurerm_resource_group.terraform-rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS2_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = var.tag
  }
}
module "module" {
  source = "./module"
  tag = "prod"
  subnetname = "subnetzub"
  rgname = "zubrgname"
}