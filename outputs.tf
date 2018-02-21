output "web_host" {
    value = "${azurerm_public_ip.vmss.fqdn}"
}

output "jump_host" {
    value = "${azurerm_public_ip.jumphost.fqdn}"
}

output "mysql_user" {
    value = "${azurerm_mysql_server.db.administrator_login}"
}

output "mysql_pass" {
    value = "${azurerm_mysql_server.db.administrator_login_password}"
}

output "mysql_host" {
    value = "${azurerm_mysql_server.db.fqdn}"
}
