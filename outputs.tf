output "web_host" {
    value = "${azurerm_public_ip.vmss.fqdn}"
}

output "jump_host" {
    value = "${azurerm_public_ip.jumphost.fqdn}"
}
