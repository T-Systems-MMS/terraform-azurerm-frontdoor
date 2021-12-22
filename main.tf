/**
 * # frontdoor
 *
 * This module manages Azure FrontDoor.
 *
*/

/** FrontDoor WebApplication Firewall */
resource "azurerm_frontdoor_firewall_policy" "frontdoor_firewall_policy" {
  for_each = var.resource_name.frontdoor_firewall_policy

  name                              = each.value
  resource_group_name               = var.resource_group_name
  enabled                           = local.frontdoor_firewall_policy.enabled
  mode                              = local.frontdoor_firewall_policy.mode
  custom_block_response_status_code = local.frontdoor_firewall_policy.custom_block_response_status_code

  dynamic "managed_rule" {
    for_each = local.frontdoor_firewall_config[each.key].managed_rule
    content {
      type    = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].type
      version = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].version

      dynamic "override" {
        for_each = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override
        content {
          rule_group_name = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override[override.key].rule_group_name

          dynamic "rule" {
            for_each = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override[override.key].rule
            content {
              action  = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].action
              enabled = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].enabled
              rule_id = local.frontdoor_firewall_config[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].rule_id
            }
          }
        }
      }
    }
  }

  dynamic "custom_rule" {
    for_each = local.frontdoor_firewall_config[each.key].custom_rule
    content {
      name     = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].name
      action   = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].action
      enabled  = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].enabled
      priority = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].priority
      type     = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].type

      dynamic "match_condition" {
        for_each = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].match_conditions
        content {
          match_variable     = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].match_variable
          operator           = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].operator
          negation_condition = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].negation_condition
          match_values       = local.frontdoor_firewall_config[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].match_values
        }
      }
    }
  }

  tags = {
    for tag in keys(local.tags) :
    tag => local.tags[tag]
  }
}

/** FrontDoor */
resource "azurerm_frontdoor" "frontdoor" {
  for_each = var.resource_name.frontdoor

  name                                         = each.value
  resource_group_name                          = var.resource_group_name
  location                                     = var.location
  backend_pools_send_receive_timeout_seconds   = local.frontdoor.backend_pools_send_receive_timeout_seconds
  enforce_backend_pools_certificate_name_check = local.frontdoor.enforce_backend_pools_certificate_name_check

  dynamic "backend_pool_health_probe" {
    for_each = local.frontdoor_config[each.key].backend_pool_health_probe
    content {
      name                = lookup(local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key], "name", backend_pool_health_probe.key)
      enabled             = local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key].enabled
      path                = local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key].path
      probe_method        = local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key].probe_method
      protocol            = local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key].protocol
      interval_in_seconds = local.frontdoor_config[each.key].backend_pool_health_probe[backend_pool_health_probe.key].interval_in_seconds
    }
  }

  dynamic "backend_pool_load_balancing" {
    for_each = local.frontdoor_config[each.key].backend_pool_load_balancing
    content {
      name = lookup(local.frontdoor_config[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key], "name", backend_pool_load_balancing.key)
    }
  }

  dynamic "backend_pool" {
    for_each = local.frontdoor_config[each.key].backend_pool
    content {
      name                = lookup(local.frontdoor_config[each.key].backend_pool[backend_pool.key], "name", backend_pool.key)
      load_balancing_name = local.frontdoor_config[each.key].backend_pool[backend_pool.key].load_balancing_name
      health_probe_name   = local.frontdoor_config[each.key].backend_pool[backend_pool.key].health_probe_name
      backend {
        address     = local.frontdoor_config[each.key].backend_pool[backend_pool.key].address
        host_header = local.frontdoor_config[each.key].backend_pool[backend_pool.key].host_header
        http_port   = local.frontdoor_config[each.key].backend_pool[backend_pool.key].http_port
        https_port  = local.frontdoor_config[each.key].backend_pool[backend_pool.key].https_port
      }
    }
  }

  dynamic "frontend_endpoint" {
    for_each = local.frontdoor_config[each.key].frontend_endpoint
    content {
      name                                    = lookup(local.frontdoor_config[each.key].frontend_endpoint[frontend_endpoint.key], "name", frontend_endpoint.key)
      host_name                               = local.frontdoor_config[each.key].frontend_endpoint[frontend_endpoint.key].host_name
      web_application_firewall_policy_link_id = local.frontdoor_config[each.key].frontend_endpoint[frontend_endpoint.key].web_application_firewall_policy_link_id
    }
  }

  dynamic "routing_rule" {
    for_each = local.frontdoor_config[each.key].routing_rule
    content {
      name               = lookup(local.frontdoor_config[each.key].routing_rule[routing_rule.key], "name", routing_rule.key)
      accepted_protocols = local.frontdoor_config[each.key].routing_rule[routing_rule.key].accepted_protocols
      patterns_to_match  = local.frontdoor_config[each.key].routing_rule[routing_rule.key].patterns_to_match
      frontend_endpoints = local.frontdoor_config[each.key].routing_rule[routing_rule.key].frontend_endpoints
      /** if forwarding_configuration is set */
      dynamic "forwarding_configuration" {
        for_each = local.frontdoor_config[each.key].routing_rule[routing_rule.key].configuration == "forwarding_configuration" ? [1] : []
        content {
          forwarding_protocol                   = local.frontdoor_config[each.key].routing_rule[routing_rule.key].forwarding_protocol
          backend_pool_name                     = local.frontdoor_config[each.key].routing_rule[routing_rule.key].backend_pool_name
          cache_enabled                         = local.frontdoor_config[each.key].routing_rule[routing_rule.key].cache_enabled
          cache_use_dynamic_compression         = local.frontdoor_config[each.key].routing_rule[routing_rule.key].cache_use_dynamic_compression
          cache_query_parameter_strip_directive = local.frontdoor_config[each.key].routing_rule[routing_rule.key].cache_query_parameter_strip_directive
        }
      }
      /** if redirect_configuration is set */
      dynamic "redirect_configuration" {
        for_each = local.frontdoor_config[each.key].routing_rule[routing_rule.key].configuration == "redirect_configuration" ? [1] : []
        content {
          redirect_protocol = local.frontdoor_config[each.key].routing_rule[routing_rule.key].redirect_protocol
          redirect_type     = local.frontdoor_config[each.key].routing_rule[routing_rule.key].redirect_type
        }
      }
    }
  }

  tags = {
    for tag in keys(local.tags) :
    tag => local.tags[tag]
  }
}

/** FrontDoor Custom HTTPS */
resource "azurerm_frontdoor_custom_https_configuration" "frontdoor_custom_https_configuration" {
  for_each = var.frontdoor_custom_https_configuration

  frontend_endpoint_id              = local.frontdoor_custom_https_configuration[each.key].frontend_endpoint_id
  custom_https_provisioning_enabled = local.frontdoor_custom_https_configuration[each.key].custom_https_provisioning_enabled

  /** ssl configuration if custom_https_provisioning_enabled = true */
  dynamic "custom_https_configuration" {
    for_each = local.frontdoor_custom_https_configuration[each.key].custom_https_provisioning_enabled == true ? [1] : []
    content {
      certificate_source                         = local.frontdoor_custom_https_configuration[each.key].certificate_source
      azure_key_vault_certificate_secret_name    = local.frontdoor_custom_https_configuration[each.key].azure_key_vault_certificate_secret_name
      azure_key_vault_certificate_secret_version = local.frontdoor_custom_https_configuration[each.key].azure_key_vault_certificate_secret_version
      azure_key_vault_certificate_vault_id       = local.frontdoor_custom_https_configuration[each.key].azure_key_vault_certificate_vault_id
    }
  }
}

/** FrontDoor RulesEngine
* ToDo change to terraform resource if supported
* https://github.com/terraform-providers/terraform-provider-azurerm/issues/7455
* resource "azurerm_frontdoor_rules_engine" "frontdoor_rules_engine"
* https://docs.microsoft.com/en-us/cli/azure/ext/front-door/network/front-door/rules-engine?view=azure-cli-latest
*/
resource "azurerm_resource_group_template_deployment" "frontdoor_rules_engine" {
  for_each = var.frontdoor_rules_engine

  name                = each.key
  resource_group_name = var.resource_group_name
  deployment_mode     = local.frontdoor_rules_engine[each.key].deployment_mode

  parameters_content = <<EOF
  {
    "name": {
      "value": "${format("%s/%s", local.frontdoor_rules_engine[each.key].frontdoor_name, each.key)}"
    },
    "properties": {
      "value": {
        "resourcestate": "Enabled",
        "rules": [
                    %{for rule in keys(local.frontdoor_rules_engine_config[each.key].rules)}
                    %{if index(keys(local.frontdoor_rules_engine_config[each.key].rules), rule) > 0},{%{else}{%{endif}
                        "priority": "${local.frontdoor_rules_engine_config[each.key].rules[rule].priority}",
                        "name": "${format("%s", rule)}",
                        "matchProcessingBehavior": "${local.frontdoor_rules_engine_config[each.key].rules[rule].match_processing_behavior}",
                        "action": {
                            "requestHeaderActions": [],
                            "responseHeaderActions": [],
                            "routeConfigurationOverride": {
                                "@odata.type": "#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration",
                                %{if local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.custom_path != ""}"customPath": "${local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.custom_path}",%{else}%{endif}
                                %{if local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.custom_host != ""}"customHost": "${local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.custom_host}",%{else}%{endif}
                                "redirectProtocol": "${local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.redirect_protocol}",
                                "redirectType": "${local.frontdoor_rules_engine_config[each.key].rules[rule].action.route_configuration_override.redirect_type}"
                            }
                        },
                        "matchConditions": [
                            %{for condition in local.frontdoor_rules_engine_config[each.key].rules[rule].match_conditions}
                            %{if index(local.frontdoor_rules_engine_config[each.key].rules[rule].match_conditions, condition) > 0},{%{else}{%{endif}
                                "rulesEngineMatchValue": [%{for value in condition.match_value} "${value}"%{endfor}],
                                "rulesEngineMatchVariable": "${format("%s", condition.match_variable)}",
                                "rulesEngineOperator": "${format("%s", condition.operator)}",
                                "transforms": [%{for transforms in condition.transforms} "${transforms}"%{endfor}],
                                %{if condition.selector != ""}"selector": "${format("%s", condition.selector)}",%{else}%{endif}
                                "negateCondition": "${condition.negate_condition}"
                            }
                            %{endfor}
                        ]
                    }
                    %{endfor}
        ]
      }
    }
  }
  EOF

  template_content = file(local.frontdoor_rules_engine[each.key].template_content)
}

/**  add rules engine to routing rule */
resource "null_resource" "frontdoor_routing_rule-rules_engine" {
  for_each = local.frontdoor_rules_engine

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "az network front-door routing-rule update --name ${local.frontdoor_rules_engine[each.key].routing_rule_name} --resource-group ${var.resource_group_name} --front-door-name ${local.frontdoor_rules_engine[each.key].frontdoor_name} --rules-engine ${each.key}"
  }
}

/** remove all rules not managed by terraform */
resource "null_resource" "frontdoor_rules_engine" {
  for_each = var.resource_name.frontdoor

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    environment = {
      RULES = join("|", keys(var.frontdoor_rules_engine))
    }

    command = "for REMOVE_RULE in $(az network front-door rules-engine list --resource-group ${var.resource_group_name} --front-door-name ${each.value} --query '[].name' -o tsv | egrep -v $RULES); do $(az network front-door rules-engine delete --resource-group ${var.resource_group_name} --front-door-name ${each.value} --name $REMOVE_RULE); done"
  }
}
