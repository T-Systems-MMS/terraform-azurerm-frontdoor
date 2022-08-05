output "frontdoor_firewall_policy" {
  description = "azurerm_frontdoor_firewall_policy results"
  value = {
    for firewall_policy in keys(azurerm_frontdoor_firewall_policy.frontdoor_firewall_policy) :
    firewall_policy => {
      id = azurerm_frontdoor_firewall_policy.frontdoor_firewall_policy[firewall_policy].id
    }
  }
}

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

output "frontdoor_custom_https_configuration" {
  description = "azurerm_frontdoor_custom_https_configuration results"
  value = {
    for frontdoor_custom_https_configuration in keys(azurerm_frontdoor_custom_https_configuration.frontdoor_custom_https_configuration) :
    frontdoor_custom_https_configuration => {
      id                   = azurerm_frontdoor_custom_https_configuration.frontdoor_custom_https_configuration[frontdoor_custom_https_configuration].id
      frontend_endpoint_id = azurerm_frontdoor_custom_https_configuration.frontdoor_custom_https_configuration[frontdoor_custom_https_configuration].frontend_endpoint_id
    }
  }
}

output "frontdoor_rules_engine" {
  description = "azurerm_frontdoor_rules_engine results"
  value = {
    for frontdoor_rules_engine in keys(var.frontdoor_rules_engine) :
    frontdoor_rules_engine => {
      id   = contains(local.frontdoor_rules_engine_action.override, frontdoor_rules_engine) == true ? azurerm_resource_group_template_deployment.frontdoor_rules_engine[frontdoor_rules_engine].id : azurerm_frontdoor_rules_engine.frontdoor_rules_engine[frontdoor_rules_engine].id
      name = contains(local.frontdoor_rules_engine_action.override, frontdoor_rules_engine) == true ? azurerm_resource_group_template_deployment.frontdoor_rules_engine[frontdoor_rules_engine].name : azurerm_frontdoor_rules_engine.frontdoor_rules_engine[frontdoor_rules_engine].name
    }
  }
}
