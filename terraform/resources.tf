# Definimos nuestro grupo

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_name
  tags     = var.tag
}

# Definimos la red y subred

resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.123.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tag
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.123.0/27"]
}

# Definimos la interfaz de red

resource "azurerm_network_interface" "vnic" {
  name                = "vnic-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  tags = var.tag
}

# Definimos nuestra IP Publica

resource "azurerm_public_ip" "pip" {
  name                = "VIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tag
}

# Definimos el security group

resource "azurerm_network_security_group" "nsg1" {
  name                = "securitygroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tag

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Asociamos las reglas creadas a la subred

resource "azurerm_subnet_network_security_group_association" "nsg-link" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Definimos nuestra maquina virtual linux

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_specs.size
  admin_username      = var.vm_specs.admin_username
  network_interface_ids = [
    azurerm_network_interface.vnic.id,
  ]

  admin_ssh_key {
    username   = var.vm_specs.username
    public_key = file("${var.vm_specs.public_key}")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = "centos-8-stream-free"
    product   = "centos-8-stream-free"
    publisher = "cognosys"
  }

  source_image_reference {
    publisher = "cognosys"
    offer     = "centos-8-stream-free"
    sku       = "centos-8-stream-free"
    version   = "22.03.28"
  }
}

# Aceptamos los terminos y condiciones 

resource "azurerm_marketplace_agreement" "canonical" {
  publisher = "cognosys"
  offer     = "centos-8-stream-free"
  plan      = "centos-8-stream-free"
}

# Definimos el container registry

resource "azurerm_container_registry" "acr" {
  name                = "containerRegistryAndresAbad"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium"
  admin_enabled       = false
  tags                = var.tag
}

# Definimos el cluster de kubernetes

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "exampleaks1"
  tags                = var.tag

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Asociamos el cluster de kubernetes al container registry

resource "azurerm_role_assignment" "role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}