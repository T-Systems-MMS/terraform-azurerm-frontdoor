module "frontdoor" {
  source              = "../terraform-frontdoor"
  resource_group_name = "service-env-rg"
  resource_name = {
    frontdoor_firewall_policy = {
      env = "serviceenvfdwafpolicy"
    }
    frontdoor = {
      env = "service-env-fd"
    }
  }
  frontdoor_firewall_policy = {
    mode = "Prevention"
  }
  frontdoor_firewall_config = {
    env = {
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
            mms = {
              match_variable     = "RemoteAddr"
              operator           = "IPMatch"
              negation_condition = true
              match_values       = "127.0.0.2"
            }
          }
        }
      }
    }
  }
  frontdoor = {
    backend_pools_send_receive_timeout_seconds   = 60
    enforce_backend_pools_certificate_name_check = false
  }
  frontdoor_config = {
    env = {
      backend_pool_health_probe = {
        healthprobe = {}
      }
      backend_pool_load_balancing = {
        loadbalancing = {}
      }
      frontend_endpoint = {
        frontendendpoint = {
          host_name                               = "service-env-fd.azurefd.net"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
        mydomain-de = {
          host_name                               = "mydomain.de"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
        mydomain-com = {
          host_name                               = "mydomain.com"
          web_application_firewall_policy_link_id = module.frontdoor.frontdoor_firewall_policy.env.id
        }
      }
      backend_pool = {
        kubernetes_cluster_controller = {
          address = "0.0.0.0"
        }
      }
      routing_rule = {
        /** forwarding configuration */
        default = {
          frontend_endpoints                    = ["frontendendpoint"]
          backend_pool_name                     = "kubernetes_cluster_controller"
          forwarding_protocol                   = "MatchRequest"
          cache_enabled                         = true
          cache_use_dynamic_compression         = true
          cache_query_parameter_strip_directive = "StripNone"
        }
        kubernetes_cluster_controller = {
          frontend_endpoints                    = ["mydomain-de", "mydomain-com"]
          backend_pool_name                     = "kubernetes_cluster_controller"
          accepted_protocols                    = ["Https"]
          forwarding_protocol                   = "HttpsOnly"
          cache_enabled                         = true
          cache_use_dynamic_compression         = true
          cache_query_parameter_strip_directive = "StripAll"
        }
        /** redirect configuration */
        rewrite-http-to-https = {
          frontend_endpoints = ["mydomain-de", "mydomain-com"]
          configuration      = "redirect_configuration"
          accepted_protocols = ["Http"]
          redirect_protocol  = "HttpsOnly"
          redirect_type      = "Moved"
        }
      }
    }
  }
  frontdoor_custom_https_configuration = {
    mydomain-de = {
      frontend_endpoint_id                       = module.frontdoor.frontdoor.env.frontend_endpoint["mydomain-de"].id
      custom_https_provisioning_enabled          = true
      certificate_source                         = "AzureKeyVault"
      azure_key_vault_certificate_vault_id       = data.azurerm_key_vault.key_vault_mgmt.id
      azure_key_vault_certificate_secret_name    = data.azurerm_key_vault_secret.mydomain-de-certificate.name
      azure_key_vault_certificate_secret_version = data.azurerm_key_vault_secret.mydomain-de-certificate.version
    }
    mydomain-com = {
      frontend_endpoint_id                       = module.frontdoor.frontdoor.env.frontend_endpoint["mydomain-com"].id
      custom_https_provisioning_enabled          = true
      certificate_source                         = "AzureKeyVault"
      azure_key_vault_certificate_vault_id       = data.azurerm_key_vault.key_vault_mgmt.id
      azure_key_vault_certificate_secret_name    = data.azurerm_key_vault_secret.mydomain-com-certificate.name
      azure_key_vault_certificate_secret_version = data.azurerm_key_vault_secret.mydomain-com-certificate.version
    }
  }
  frontdoor_rules_engine = {
    mydomain-com = {
      frontdoor_name    = "service-env-fd.azurefd.net"
      routing_rule_name = "kubernetes_cluster_controller"
    }
  }
  frontdoor_rules_engine_config = {
    mydomaincom = {
      rules = {
        entire = {
          priority                  = "0"
          match_processing_behavior = "Stop"
          action = {
            route_configuration_override = {
              custom_host       = "mydomain.com"
              custom_path       = "/"
              redirect_protocol = "HttpsOnly"
              redirect_type     = "PermanentRedirect"
            }
          }
          match_conditions = [
            {
              match_value      = ["mydomain.com mydomain.com/"]
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
  tags = {
    service = "service_name"
  }
}
