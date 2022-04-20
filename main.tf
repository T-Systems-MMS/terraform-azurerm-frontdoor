/**
 * # frontdoor
 *
 * This module manages Azure FrontDoor.
 *
*/

/** FrontDoor WebApplication Firewall */
resource "azurerm_frontdoor_firewall_policy" "frontdoor_firewall_policy" {
  for_each = var.frontdoor_firewall_policy

  name                              = local.frontdoor_firewall_policy[each.key].name == "" ? each.key : local.frontdoor_firewall_policy[each.key].name
  resource_group_name               = local.frontdoor_firewall_policy[each.key].resource_group_name
  enabled                           = local.frontdoor_firewall_policy[each.key].enabled
  mode                              = local.frontdoor_firewall_policy[each.key].mode
  custom_block_response_status_code = local.frontdoor_firewall_policy[each.key].custom_block_response_status_code

  dynamic "managed_rule" {
    for_each = local.frontdoor_firewall_policy[each.key].managed_rule
    content {
      type    = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].type
      version = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].version

      dynamic "override" {
        for_each = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override
        content {
          rule_group_name = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override[override.key].rule_group_name

          dynamic "rule" {
            for_each = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override[override.key].rule
            content {
              action  = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].action
              enabled = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].enabled
              rule_id = local.frontdoor_firewall_policy[each.key].managed_rule[managed_rule.key].override[override.key].rule[rule.key].rule_id
            }
          }
        }
      }
    }
  }

  dynamic "custom_rule" {
    for_each = local.frontdoor_firewall_policy[each.key].custom_rule
    content {
      name     = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].name
      action   = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].action
      enabled  = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].enabled
      priority = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].priority
      type     = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].type

      dynamic "match_condition" {
        for_each = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].match_conditions
        content {
          match_variable     = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].match_variable
          operator           = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].operator
          negation_condition = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].negation_condition
          match_values       = local.frontdoor_firewall_policy[each.key].custom_rule[custom_rule.key].match_conditions[match_condition.key].match_values
        }
      }
    }
  }

  tags = local.frontdoor_firewall_policy[each.key].tags
}

/** FrontDoor */
resource "azurerm_frontdoor" "frontdoor" {
  for_each = var.frontdoor

  name                  = local.frontdoor[each.key].name == "" ? each.key : local.frontdoor[each.key].name
  resource_group_name   = local.frontdoor[each.key].resource_group_name
  load_balancer_enabled = local.frontdoor[each.key].load_balancer_enabled
  friendly_name         = local.frontdoor[each.key].friendly_name

  backend_pool_settings {
    backend_pools_send_receive_timeout_seconds   = local.frontdoor[each.key].backend_pool_settings.backend_pools_send_receive_timeout_seconds
    enforce_backend_pools_certificate_name_check = local.frontdoor[each.key].backend_pool_settings.enforce_backend_pools_certificate_name_check
  }

  dynamic "backend_pool" {
    for_each = local.frontdoor[each.key].backend_pool
    content {
      name                = local.frontdoor[each.key].backend_pool[backend_pool.key].name == "" ? backend_pool.key : local.frontdoor[each.key].backend_pool[backend_pool.key].name
      load_balancing_name = local.frontdoor[each.key].backend_pool[backend_pool.key].load_balancing_name
      health_probe_name   = local.frontdoor[each.key].backend_pool[backend_pool.key].health_probe_name
      backend {
        enabled     = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.enabled
        address     = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.address
        host_header = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.host_header
        http_port   = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.http_port
        https_port  = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.https_port
        priority    = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.priority
        weight      = local.frontdoor[each.key].backend_pool[backend_pool.key].backend.weight
      }
    }
  }

  dynamic "backend_pool_health_probe" {
    for_each = local.frontdoor[each.key].backend_pool_health_probe
    content {
      name                = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].name == "" ? backend_pool_health_probe.key : local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].name
      enabled             = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].enabled
      path                = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].path
      probe_method        = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].probe_method
      protocol            = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].protocol
      interval_in_seconds = local.frontdoor[each.key].backend_pool_health_probe[backend_pool_health_probe.key].interval_in_seconds
    }
  }

  dynamic "backend_pool_load_balancing" {
    for_each = local.frontdoor[each.key].backend_pool_load_balancing
    content {
      name                            = local.frontdoor[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key].name == "" ? backend_pool_load_balancing.key : local.frontdoor[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key].name
      sample_size                     = local.frontdoor[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key].sample_size
      successful_samples_required     = local.frontdoor[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key].successful_samples_required
      additional_latency_milliseconds = local.frontdoor[each.key].backend_pool_load_balancing[backend_pool_load_balancing.key].additional_latency_milliseconds
    }
  }

  dynamic "frontend_endpoint" {
    for_each = local.frontdoor[each.key].frontend_endpoint
    content {
      name                                    = local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].name == "" ? frontend_endpoint.key : local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].name
      host_name                               = local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].host_name
      session_affinity_enabled                = local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].session_affinity_enabled
      session_affinity_ttl_seconds            = local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].session_affinity_ttl_seconds
      web_application_firewall_policy_link_id = local.frontdoor[each.key].frontend_endpoint[frontend_endpoint.key].web_application_firewall_policy_link_id
    }
  }

  dynamic "routing_rule" {
    for_each = local.frontdoor[each.key].routing_rule
    content {
      name               = local.frontdoor[each.key].routing_rule[routing_rule.key].name == "" ? routing_rule.key : local.frontdoor[each.key].routing_rule[routing_rule.key].name
      accepted_protocols = local.frontdoor[each.key].routing_rule[routing_rule.key].accepted_protocols
      patterns_to_match  = local.frontdoor[each.key].routing_rule[routing_rule.key].patterns_to_match
      enabled            = local.frontdoor[each.key].routing_rule[routing_rule.key].enabled
      frontend_endpoints = local.frontdoor[each.key].routing_rule[routing_rule.key].frontend_endpoints
      /** if forwarding_configuration is set */
      dynamic "forwarding_configuration" {
        for_each = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.forwarding_protocol != "" ? [1] : []
        content {
          forwarding_protocol                   = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.forwarding_protocol
          backend_pool_name                     = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.backend_pool_name
          cache_enabled                         = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.cache_enabled
          cache_use_dynamic_compression         = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.cache_use_dynamic_compression
          cache_query_parameter_strip_directive = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.cache_query_parameter_strip_directive
          cache_query_parameters                = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.cache_query_parameters
          cache_duration                        = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.cache_duration
          custom_forwarding_path                = local.frontdoor[each.key].routing_rule[routing_rule.key].forwarding_configuration.custom_forwarding_path
        }
      }
      /** if redirect_configuration is set */
      dynamic "redirect_configuration" {
        for_each = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.redirect_protocol != "" ? [1] : []
        content {
          custom_host         = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.custom_host
          redirect_protocol   = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.redirect_protocol
          redirect_type       = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.redirect_type
          custom_fragment     = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.custom_fragment
          custom_path         = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.custom_path
          custom_query_string = local.frontdoor[each.key].routing_rule[routing_rule.key].redirect_configuration.custom_query_string
        }
      }
    }
  }

  tags = local.frontdoor[each.key].tags
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

  name                = local.frontdoor_rules_engine[each.key].name == "" ? each.key : local.frontdoor_rules_engine[each.key].name
  resource_group_name = local.frontdoor_rules_engine[each.key].resource_group_name
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
                    %{for rule in keys(local.frontdoor_rules_engine[each.key].rules)}
                    %{if index(keys(local.frontdoor_rules_engine[each.key].rules), rule) > 0},{%{else}{%{endif}
                        "priority": "${local.frontdoor_rules_engine[each.key].rules[rule].priority}",
                        "name": "${format("%s", rule)}",
                        "matchProcessingBehavior": "${local.frontdoor_rules_engine[each.key].rules[rule].match_processing_behavior}",
                        "action": {
                            "requestHeaderActions": [],
                            "responseHeaderActions": [],
                            "routeConfigurationOverride": {
                                "@odata.type": "#Microsoft.Azure.FrontDoor.Models.FrontdoorRedirectConfiguration",
                                %{if local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.custom_path != ""}"customPath": "${local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.custom_path}",%{else}%{endif}
                                %{if local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.custom_host != ""}"customHost": "${local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.custom_host}",%{else}%{endif}
                                "redirectProtocol": "${local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.redirect_protocol}",
                                "redirectType": "${local.frontdoor_rules_engine[each.key].rules[rule].action.route_configuration_override.redirect_type}"
                            }
                        },
                        "matchConditions": [
                            %{for condition in local.frontdoor_rules_engine[each.key].rules[rule].match_conditions}
                            %{if index(local.frontdoor_rules_engine[each.key].rules[rule].match_conditions, condition) > 0},{%{else}{%{endif}
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
  for_each = var.frontdoor_rules_engine

  triggers = {
    routing_rule       = local.frontdoor_rules_engine[each.key].routing_rule_name
    frontdoor_name     = local.frontdoor_rules_engine[each.key].frontdoor_name
    parameters_content = azurerm_resource_group_template_deployment.frontdoor_rules_engine[each.key].parameters_content
  }

  provisioner "local-exec" {
    command = "az network front-door routing-rule update --name ${local.frontdoor_rules_engine[each.key].routing_rule_name} --resource-group ${azurerm_resource_group_template_deployment.frontdoor_rules_engine[each.key].resource_group_name} --front-door-name ${local.frontdoor_rules_engine[each.key].frontdoor_name} --rules-engine ${azurerm_resource_group_template_deployment.frontdoor_rules_engine[each.key].name}"
  }
}

/** remove all rules not managed by terraform */
resource "null_resource" "frontdoor_rules_engine" {
  for_each = var.frontdoor

  triggers = {
    frontdoor_name = azurerm_frontdoor.frontdoor[each.key].name
    rules_engine   = join(" ", keys(var.frontdoor_rules_engine))
  }

  provisioner "local-exec" {
    environment = {
      RULES = join("|", keys(var.frontdoor_rules_engine))
    }

    command = "for REMOVE_RULE in $(az network front-door rules-engine list --resource-group ${azurerm_frontdoor.frontdoor[each.key].resource_group_name} --front-door-name ${azurerm_frontdoor.frontdoor[each.key].name} --query '[].name' -o tsv | egrep -v $RULES); do $(az network front-door rules-engine delete --resource-group ${azurerm_frontdoor.frontdoor[each.key].resource_group_name} --front-door-name ${azurerm_frontdoor.frontdoor[each.key].name} --name $REMOVE_RULE); done"
  }
}
