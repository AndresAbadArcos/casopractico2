# Variable con el nombre del grupo

variable "resource_group_name" {
  default = "CP2"
}

# Variable de la región donde se va a crear la infraestructura

variable "location_name" {
  default = "uksouth"
}

# Variable con el nombre de la red

variable "network_name" {
  default = "vnet1"
}

# Variable con el nombre de la subred

variable "subnet_name" {
  default = "subnet1"
}

# Variables para la maquina virtual a desplegar

variable "vm_specs" {
  type = object({
    count          = number
    basename       = string
    size           = string
    admin_username = string
    username       = string
    public_key      = string
  })

  sensitive = true

  default = {
    count          = 3
    basename       = "vm0"
    size           = "Standard_B1s"
    admin_username = "azureuser"
    username       = "azureuser"
    public_key     = "~/.ssh/id_rsa.pub"
  }
}

# Variable de tag

variable "tag" {
  default = {
    environment = "casopractico2"
  }
}