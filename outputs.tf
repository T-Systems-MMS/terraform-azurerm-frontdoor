output "frontdoor" {
  description = "azurerm_frontdoor results"
  value = {
    for frontdoor in keys(azurerm_frontdoor.frontdoor) :
    frontdoor => {
      id                 = azurerm_frontdoor.frontdoor[frontdoor].id
      name               = azurerm_frontdoor.frontdoor[frontdoor].name
      frontend_endpoints = azurerm_frontdoor.frontdoor[frontdoor].frontend_endpoints
    }
  }
}

output "frontdoor_firewall_policy" {
  description = "azurerm_frontdoor_firewall_policy results"
  value = {
    for firewall_policy in keys(azurerm_frontdoor_firewall_policy.frontdoor_firewall_policy) :
    firewall_policy => {
      id = azurerm_frontdoor_firewall_policy.frontdoor_firewall_policy[firewall_policy].id
    }
  }
}
