<!-- BEGIN_TF_DOCS -->
# frontdoor

This module manages Azure FrontDoor.

<-- This file is autogenerated, please do not change. -->

## Requirements

| Name | Version |
|------|---------|
| terraform | ~>1.0 |
| azurerm | >=3.15 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >=3.15 |
| null | n/a |

## Resources

| Name | Type |
|------|------|
| azurerm_frontdoor.frontdoor | resource |
| azurerm_frontdoor_custom_https_configuration.frontdoor_custom_https_configuration | resource |
| azurerm_frontdoor_firewall_policy.frontdoor_firewall_policy | resource |
| azurerm_frontdoor_rules_engine.frontdoor_rules_engine | resource |
| azurerm_resource_group_template_deployment.frontdoor_rules_engine | resource |
| [null_resource.frontdoor_routing_rule-rules_engine](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.frontdoor_rules_engine](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| frontdoor | resource definition, default settings are defined within locals and merged with var settings | `any` | `{}` | no |
| frontdoor_custom_https_configuration | resource definition, default settings are defined within locals and merged with var settings | `any` | `{}` | no |
| frontdoor_firewall_policy | resource definition, default settings are defined within locals and merged with var settings | `any` | `{}` | no |
| frontdoor_rules_engine | resource definition, default settings are defined within locals and merged with var settings | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| frontdoor | azurerm_frontdoor results |
| frontdoor_custom_https_configuration | azurerm_frontdoor_custom_https_configuration results |
| frontdoor_firewall_policy | azurerm_frontdoor_firewall_policy results |
| frontdoor_rules_engine | azurerm_frontdoor_rules_engine results |

## Examples

```hcl
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
        }
        Microsoft_DefaultRuleSet = {
          type    = "Microsoft_DefaultRuleSet"
          version = "1.1"
          override = {
            XSS = {
              rule_group_name = "XSS"
              rule = {
                941220 = {
                  rule_id = "941220"
                }
                941221 = {
                  action  = "Log"
                  enabled = true
                  rule_id = "941221"
                }
              }
            }
            SQLI = {
              rule_group_name = "SQLI"
              exclusion = {
                not_suspicious = {
                  match_variable = "QueryStringArgNames"
                  operator       = "Equals"
                  selector       = "really_not_suspicious"
                }
              }
            }
          }
        }
      }
      custom_rule = {
        iprestriction = {
          priority = 0
          type     = "MatchRule"
          match_condition = {
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
            cache_enabled       = false
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
      frontdoor_name      = module.frontdoor.frontdoor.env.name
      resource_group_name = "service-env-rg"
      routing_rule_name   = "kubernetes_cluster_controller non-backend"
      rule = {
        redirectde = {
          priority                  = "0"
          action = {
            route_configuration_override = {
              custom_host       = "domain-de"
              custom_path       = "/"
              redirect_type     = "PermanentRedirect"
            }
          }
          match_condition = {
            header = {
              variable = "RequestHeader"
              selector = "accept-language"
              operator = "Contains"
              value    = ["de"]
            }
            uri = {
              variable = "RequestUri"
              operator = "EndsWith"
              value    = ["domain.com domain.com/"]
            }
          }
        }
      }
    }
  }
}
```
<!-- END_TF_DOCS -->