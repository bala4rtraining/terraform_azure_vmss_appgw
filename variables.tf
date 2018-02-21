variable "resource_group_name" {
  description = "Name of resource group and all resources"
  default     = "hippo01"
}

variable "location" {
  description = "Location where resources will be created"
  default     = "West Europe"
}

variable "vm_username" {
    description = "Username for SSH access"
    default = "hippoadmin"
}

variable "vm_password" {
    description = "Password for SSH access"
    default = "Qwerty1234!!"
}

variable "vmss_type" {
    description = "Size of VMs in the scale set"
    default = "Standard_DS1_v2"
}
variable "vm_count" {
    description = "Number of instances in the scale set"
    default = "2"
}

variable "address_space" {
    description = "Address space available in vnet"
    default = "10.44.0.0/16"
}

variable "subnet_vmss" {
    description = "Subnet for VMSS"
    default = "10.44.0.0/24"
}

variable "subnet_gw" {
    description = "Subnet for application gateway"
    default = "10.44.254.0/24"
}

variable "ag_count" {
    description = "Application gateway instance count"
    default = "2"
}

variable "ag_name" {
    description = "Application gateway instance count"
    default = "Standard_Medium"
}

variable "data_replication" {
    description = "Type of data replication for storage account"
    default = "GRS"
}

variable "data_quota" {
    description = "Disk quota in GB for the storage account"
    default = "5"
}

variable "db_user" {
    description = "Database username"
    default = "hippoadmin"
}
variable "db_pass" {
    description = "Database password"
    default = "Qwerty1234!!"
}
variable "db_quota" {
    description = "Database quota in MB"
    default = "5120"
}
