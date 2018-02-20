variable "location" {
  description = "The location where resources will be created"
  default     = "West Europe"
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "hippo01"
}

variable "vm_username" {
    description = "Default username for admin access"
    default = "hippoadmin"
}

variable "vm_password" {
    description = "Default password for admin access"
    default = "Qwerty1234!!"
}
