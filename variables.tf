variable "frontdoor_firewall_policy" {
  type        = any
  default     = {}
  description = "resource definition, default settings are defined within locals and merged with var settings"
}
variable "frontdoor" {
  type        = any
  default     = {}
  description = "resource definition, default settings are defined within locals and merged with var settings"
}
variable "frontdoor_custom_https_configuration" {
  type        = any
  default     = {}
  description = "resource definition, default settings are defined within locals and merged with var settings"
}
variable "frontdoor_rules_engine" {
  type        = any
  default     = {}
  description = "resource definition, default settings are defined within locals and merged with var settings"
}

locals {
  default = {
    # resource definition
    frontdoor_firewall_policy = {
      name                              = ""
      enabled                           = true
      mode                              = "Prevention"
      redirect_url                      = null
      custom_block_response_status_code = 403
      custom_block_response_body        = null
      custom_rule = {
        name                           = ""
        action                         = "Block"
        enabled                        = true
        type                           = "MatchRule"
        rate_limit_duration_in_minutes = 1
        rate_limit_threshold           = 10
        match_condition = {
          selector           = null
          negation_condition = null
          transforms         = null
        }
      }
      managed_rule = {
        exclusion = {}
        override = {
          exclusion = {}
          rule = {
            action    = "Block"
            enabled   = true
            exclusion = {}
          }
        }
      }
      tags = {}
    }
    frontdoor = {
      name                  = ""
      load_balancer_enabled = true
      friendly_name         = null
      backend_pool_settings = {
        backend_pools_send_receive_timeout_seconds   = "30"
        enforce_backend_pools_certificate_name_check = true
      }
      backend_pool_health_probe = {
        name                = ""
        enabled             = true
        path                = "/"
        probe_method        = "HEAD"
        protocol            = "Https"
        interval_in_seconds = "30"
      }
      backend_pool_load_balancing = {
        name                            = ""
        sample_size                     = 4
        successful_samples_required     = 2
        additional_latency_milliseconds = 0
      }
      backend_pool = {
        name = ""
        backend = {
          enabled     = true
          host_header = ""
          http_port   = 80
          https_port  = 443
          priority    = 1
          weight      = 50
        }
      }
      frontend_endpoint = {
        name                                    = ""
        session_affinity_enabled                = false
        session_affinity_ttl_seconds            = 0
        web_application_firewall_policy_link_id = ""
      }
      routing_rule = {
        name               = ""
        backend_pool_name  = "default"
        accepted_protocols = ["Http", "Https"]
        patterns_to_match  = ["/*"]
        enabled            = true
        frontend_endpoints = ["frontendendpoint"]
        forwarding_configuration = {
          forwarding_protocol                   = ""
          patterns_to_match                     = ["/*"]
          cache_enabled                         = true
          cache_use_dynamic_compression         = true
          cache_query_parameter_strip_directive = "StripNone"
          cache_query_parameters                = null
          cache_duration                        = "P1D"
          custom_forwarding_path                = null
        }
        redirect_configuration = {
          custom_host         = null
          redirect_protocol   = ""
          redirect_type       = "Found"
          custom_fragment     = null
          custom_path         = null
          custom_query_string = null
        }
      }
      tags = {}
    }
    frontdoor_custom_https_configuration = {
      custom_https_provisioning_enabled          = false
      certificate_source                         = "FrontDoor"
      azure_key_vault_certificate_vault_id       = ""
      azure_key_vault_certificate_secret_name    = ""
      azure_key_vault_certificate_secret_version = ""
    }
    frontdoor_rules_engine = {
      name = ""
      rule = {
        name                      = ""
        match_processing_behavior = "Stop"
        action = {
          request_header  = {}
          response_header = {}
          route_configuration_override = {
            custom_path       = null
            custom_host       = null
            redirect_protocol = "HttpsOnly"
            redirect_type     = "Found"
          }
        }
        match_condition = {
          selector         = null
          transform        = null
          negate_condition = false
        }
      }
      /** needed for route_configuration_override */
      template_content = format("%s/templates/frontdoor_rules_engine.json", path.module)
      deployment_mode  = "Incremental"
    }
  }

  # compare and merge custom and default values
  frontdoor_firewall_policy_values = {
    for frontdoor_firewall_policy in keys(var.frontdoor_firewall_policy) :
    frontdoor_firewall_policy => merge(
      merge(local.default.frontdoor_firewall_policy, var.frontdoor_firewall_policy[frontdoor_firewall_policy]),
      {
        for config in ["custom_rule", "managed_rule"] :
        config => lookup(var.frontdoor_firewall_policy[frontdoor_firewall_policy], config, {})
      }
    )
  }
  frontdoor_firewall_policy_custom_rule_values = {
    for frontdoor_firewall_policy in keys(var.frontdoor_firewall_policy) :
    frontdoor_firewall_policy => {
      for key in keys(local.frontdoor_firewall_policy_values[frontdoor_firewall_policy].custom_rule) :
      key => merge(local.default.frontdoor_firewall_policy.custom_rule, local.frontdoor_firewall_policy_values[frontdoor_firewall_policy].custom_rule[key])
    }
  }
  frontdoor_firewall_policy_managed_rule_values = {
    for frontdoor_firewall_policy in keys(var.frontdoor_firewall_policy) :
    frontdoor_firewall_policy => {
      for key in keys(local.frontdoor_firewall_policy_values[frontdoor_firewall_policy].managed_rule) :
      key => merge(local.default.frontdoor_firewall_policy.managed_rule, local.frontdoor_firewall_policy_values[frontdoor_firewall_policy].managed_rule[key])
    }
  }
  frontdoor_values = {
    for frontdoor in keys(var.frontdoor) :
    frontdoor => merge(local.default.frontdoor, var.frontdoor[frontdoor])
  }
  frontdoor_backend_pool_values = {
    for frontdoor in keys(var.frontdoor) :
    frontdoor => {
      for key in keys(local.frontdoor_values[frontdoor].backend_pool) :
      key => merge(local.default.frontdoor.backend_pool, local.frontdoor_values[frontdoor].backend_pool[key])
    }
  }
  frontdoor_routing_rule_values = {
    for frontdoor in keys(var.frontdoor) :
    frontdoor => {
      for key in keys(local.frontdoor_values[frontdoor].routing_rule) :
      key => merge(local.default.frontdoor.routing_rule, local.frontdoor_values[frontdoor].routing_rule[key])
    }
  }
  frontdoor_rules_engine_values = {
    for frontdoor_rules_engine in keys(var.frontdoor_rules_engine) :
    frontdoor_rules_engine => merge(local.default.frontdoor_rules_engine, var.frontdoor_rules_engine[frontdoor_rules_engine])
  }
  frontdoor_rules_engine_rule_values = {
    for frontdoor_rules_engine in keys(var.frontdoor_rules_engine) :
    frontdoor_rules_engine => {
      for key in keys(local.frontdoor_rules_engine_values[frontdoor_rules_engine].rule) :
      key => merge(local.default.frontdoor_rules_engine.rule, local.frontdoor_rules_engine_values[frontdoor_rules_engine].rule[key])
    }
  }
  # merge all custom and default values
  frontdoor_firewall_policy = {
    for frontdoor_firewall_policy in keys(var.frontdoor_firewall_policy) :
    frontdoor_firewall_policy => merge(
      local.frontdoor_firewall_policy_values[frontdoor_firewall_policy],
      {
        custom_rule = {
          for key in keys(local.frontdoor_firewall_policy_custom_rule_values[frontdoor_firewall_policy]) :
          key => merge(
            local.frontdoor_firewall_policy_custom_rule_values[frontdoor_firewall_policy][key],
            {
              for config in ["match_condition"] :
              config => {
                for configkey in keys(local.frontdoor_firewall_policy_custom_rule_values[frontdoor_firewall_policy][key][config]) :
                configkey => merge(local.default.frontdoor_firewall_policy.custom_rule[config], local.frontdoor_firewall_policy_custom_rule_values[frontdoor_firewall_policy][key][config][configkey])
              }
            }
          )
        }
        managed_rule = {
          for key in keys(local.frontdoor_firewall_policy_managed_rule_values[frontdoor_firewall_policy]) :
          key => merge(
            local.frontdoor_firewall_policy_managed_rule_values[frontdoor_firewall_policy][key],
            {
              for config in ["exclusion", "override"] :
              config => {
                for configkey in keys(lookup(local.frontdoor_firewall_policy_values[frontdoor_firewall_policy].managed_rule[key], config, {})) :
                configkey => merge(
                  merge(local.default.frontdoor_firewall_policy.managed_rule[config], local.frontdoor_firewall_policy_managed_rule_values[frontdoor_firewall_policy][key][config][configkey]),
                  {
                    for subconfig in ["exclusion", "rule"] :
                    subconfig => {
                      for subconfigkey in keys(lookup(local.frontdoor_firewall_policy_managed_rule_values[frontdoor_firewall_policy][key][config][configkey], subconfig, {})) :
                      subconfigkey => merge(local.default.frontdoor_firewall_policy.managed_rule[config][subconfig], local.frontdoor_firewall_policy_managed_rule_values[frontdoor_firewall_policy][key][config][configkey][subconfig][subconfigkey])
                    }
                  }
                )
              }
            }
          )
        }
      }
    )
  }
  frontdoor = {
    for frontdoor in keys(var.frontdoor) :
    frontdoor => merge(
      local.frontdoor_values[frontdoor],
      {
        for config in ["backend_pool_settings"] :
        config => merge(local.default.frontdoor[config], local.frontdoor_values[frontdoor][config])
      },
      {
        for config in ["backend_pool_health_probe", "backend_pool_load_balancing", "frontend_endpoint"] :
        config => {
          for key in keys(local.frontdoor_values[frontdoor][config]) :
          key => merge(local.default.frontdoor[config], local.frontdoor_values[frontdoor][config][key])
        }
      },
      {
        backend_pool = {
          for key in keys(local.frontdoor_backend_pool_values[frontdoor]) :
          key => merge(
            local.frontdoor_backend_pool_values[frontdoor][key],
            {
              for config in ["backend"] :
              config => merge(local.default.frontdoor.backend_pool[config], local.frontdoor_backend_pool_values[frontdoor][key][config])
            }
          )
        }
      },
      {
        routing_rule = {
          for key in keys(local.frontdoor_routing_rule_values[frontdoor]) :
          key => merge(
            local.frontdoor_routing_rule_values[frontdoor][key],
            {
              for config in ["forwarding_configuration", "redirect_configuration"] :
              config => merge(local.default.frontdoor.routing_rule[config], local.frontdoor_routing_rule_values[frontdoor][key][config])
            }
          )
        }
      }
    )
  }
  frontdoor_custom_https_configuration = {
    for frontdoor_custom_https_configuration in keys(var.frontdoor_custom_https_configuration) :
    frontdoor_custom_https_configuration => merge(local.default.frontdoor_custom_https_configuration, var.frontdoor_custom_https_configuration[frontdoor_custom_https_configuration])
  }
  frontdoor_rules_engine = {
    for frontdoor_rules_engine in keys(var.frontdoor_rules_engine) :
    frontdoor_rules_engine => merge(
      local.frontdoor_rules_engine_values[frontdoor_rules_engine],
      {
        rule = {
          for rulekey in keys(local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine]) :
          rulekey => merge(
            local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine][rulekey],
            {
              for config in ["action"] :
              config => merge(
                merge(local.default.frontdoor_rules_engine.rule[config], local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine][rulekey][config]),
                {
                  for subconfig in ["route_configuration_override"] :
                  subconfig => merge(local.default.frontdoor_rules_engine.rule[config][subconfig], local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine][rulekey][config][subconfig])
                }
              )
            },
            {
              for config in ["match_condition"] :
              config => {
                for key in keys(local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine][rulekey][config]) :
                key => merge(local.default.frontdoor_rules_engine.rule[config], local.frontdoor_rules_engine_rule_values[frontdoor_rules_engine][rulekey][config][key])
              }
            }
          )
        }
      }
    )
  }

  /** needed to split between resource and template setup
  * resource "azurerm_frontdoor_rules_engine" "frontdoor_rules_engine"
  * resource "azurerm_resource_group_template_deployment" "frontdoor_rules_engine"
  */
  frontdoor_rules_engine_keys = {
    for engine_key, engine_match in {
      header   = false
      override = true
    } :
    engine_key => compact(distinct(flatten(
      [
        for frontdoor_rules_engine in keys(local.frontdoor_rules_engine) : [
          for rulekey in keys(local.frontdoor_rules_engine[frontdoor_rules_engine].rule) :
          contains(keys(local.frontdoor_rules_engine[frontdoor_rules_engine].rule[rulekey].action), "route_configuration_override") == engine_match ? frontdoor_rules_engine : ""
        ]
      ]
    )))
  }
}
