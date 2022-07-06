module "frontdoor" {
  source = "registry.terraform.io/T-Systems-MMS/frontdoor/azurerm"
  frontdoor_firewall_policy = {
    env = {
      name                = "servicefdwafpolicy"
      resource_group_name = local.resource_group_name.environment
      mode                = "Prevention"
      managed_rule = {
        Microsoft_BotManagerRuleSet = {
          type     = "Microsoft_BotManagerRuleSet"
          version  = "1.0"
          override = []
        }
      }
      custom_rule = {
        ip_access = {
          name     = "iprestriction"
          action   = "Block"
          enabled  = true
          priority = 0
          type     = "MatchRule"
          match_conditions = {
            localhost = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = true
              match_values       = "172.0.0.1"
            }
          }
        }
      }
      tags = {
        environment = "env"
      }
    }
  }
  frontdoor = {
    env = {
      name                = "service-env-fd"
      resource_group_name = "service-env-rg"
      backend_pool_settings = {
        backend_pools_send_receive_timeout_seconds   = 60
        enforce_backend_pools_certificate_name_check = true
      }
      backend_pool_health_probe = {
        healthprobe = {}
      }
      backend_pool_load_balancing = {
        loadbalancing = {}
      }
      backend_pool = {
        "kubernetes_cluster_controller" = {
          load_balancing_name = "loadbalancing"
          health_probe_name   = "healthprobe"
          backend = {
            address = "1.1.1.1"
          }
        }
        non-backend = {
          load_balancing_name = "loadbalancing"
          health_probe_name   = "healthprobe"
          backend = {
            address = "0.0.0.0"
          }
        }
      }
      frontend_endpoint = {
        frontendendpoint = {
          host_name                               = "service-env-fd.azurefd.net"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
        domain-com = {
          host_name                               = "domain.com"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
        domain-de = {
          host_name                               = "domain.de"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
      }
      routing_rule = {
        default = {
          frontend_endpoints = ["frontendendpoint"]
          forwarding_configuration = {
            backend_pool_name   = "kubernetes_cluster_controller"
            forwarding_protocol = "MatchRequest"
          }
        }
        kubernetes_cluster_controller = {
          frontend_endpoints = ["domain-com"]
          patterns_to_match  = ["/*"]
          accepted_protocols = ["Https"]
          forwarding_configuration = {
            backend_pool_name                     = "kubernetes_cluster_controller"
            forwarding_protocol                   = "HttpsOnly"
            cache_query_parameter_strip_directive = "StripAll"
          }
        }
        non-backend = {
          frontend_endpoints = ["domain-de"]
          accepted_protocols = ["Https"]
          forwarding_configuration = {
            backend_pool_name                     = "non-backend"
            forwarding_protocol                   = "HttpsOnly"
            cache_query_parameter_strip_directive = "StripAll"
          }
        }
        rewrite-http-to-https = {
          frontend_endpoints = ["domain-com", "domain-de"]
          accepted_protocols = ["Http"]
          redirect_configuration = {
            redirect_protocol = "HttpsOnly"
            redirect_type     = "Moved"
          }
        }
      }
      tags = {
        service = "service_name"
      }
    }
  }
  frontdoor_custom_https_configuration = {
    "domain-com" = {
      frontend_endpoint_id                       = module.frontdoor.frontdoor.env.frontend_endpoints["domain-com"]
      custom_https_provisioning_enabled          = true
      certificate_source                         = "AzureKeyVault"
      azure_key_vault_certificate_vault_id       = data.azurerm_key_vault.key_vault_mgmt.id
      azure_key_vault_certificate_secret_name    = "certificate_secret_name"
      azure_key_vault_certificate_secret_version = "certificate_secret_version"
    }
  }
  frontdoor_rules_engine = {
    derules = {
      resource_group_name = "service-env-rg"
      frontdoor_name      = module.frontdoor.frontdoor.env.name
      routing_rule_name   = "kubernetes_cluster_controller non-backend"
      rules = {
        entire = {
          priority                  = "0"
          match_processing_behavior = "Stop"
          action = {
            route_configuration_override = {
              custom_host       = "domain-de"
              custom_path       = "/"
              redirect_protocol = "HttpsOnly"
              redirect_type     = "PermanentRedirect"
            }
          }
          match_conditions = [
            {
              match_value      = ["domain-de domain-de/"]
              match_variable   = "RequestUri"
              operator         = "Equal"
              negate_condition = false
              selector         = ""
              transforms       = []
            }
          ]
        }
      }
    }
  }
}
