variable "resource_name" {
  type        = any
  default     = {}
  description = "Azure FrontDoor"
}
variable "location" {
  type        = string
  default     = "global"
  description = "location where the resource should be created"
}
variable "resource_group_name" {
  type        = string
  description = "resource_group whitin the resource should be created"
}
variable "tags" {
  type        = any
  default     = {}
  description = "mapping of tags to assign, default settings are defined within locals and merged with var settings"
}
# resource definition
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
# resource configuration
variable "frontdoor_firewall_config" {
  type        = any
  default     = {}
  description = "resource configuration, default settings are defined within locals and merged with var settings"
}
variable "frontdoor_config" {
  type        = any
  default     = {}
  description = "resource configuration, default settings are defined within locals and merged with var settings"
}
variable "frontdoor_rules_engine_config" {
  type        = any
  default     = {}
  description = "resource configuration, default settings are defined within locals and merged with var settings"
}

locals {
  # default values
  default = {
    # resource definition
    tags = {}

    frontdoor_firewall_policy = {
      enabled                           = true
      mode                              = "Prevention"
      custom_block_response_status_code = 403
    }
    frontdoor = {
      template_deployment                          = false
      enforce_backend_pools_certificate_name_check = true
    }
    frontdoor_custom_https_configuration = {
      custom_https_provisioning_enabled          = false
      certificate_source                         = "FrontDoor"
      azure_key_vault_certificate_vault_id       = ""
      azure_key_vault_certificate_secret_name    = ""
      azure_key_vault_certificate_secret_version = ""
    }
    frontdoor_rules_engine = {
      deployment_mode  = "Incremental"
      template_content = format("%s/templates/frontdoor_rules_engine.json", path.module)
    }
    # resource configuration
    frontdoor_firewall_config = {
      managed_rule = {}
      custom_rule  = {}
    }
    frontdoor_config = {
      backend_pool_health_probe = {
        enabled             = true
        path                = "/"
        probe_method        = "HEAD"
        protocol            = "Https"
        interval_in_seconds = "30"
      }
      backend_pool_load_balancing = {}
      backend_pool = {
        load_balancing_name = "loadbalancing"
        health_probe_name   = "healthprobe"
        # backend
        address     = "0.0.0.0"
        host_header = ""
        http_port   = 80
        https_port  = 443
      }
      frontend_endpoint = {
        host_name                               = "fd.azurefd.net"
        web_application_firewall_policy_link_id = ""
      }
      routing_rule = {
        backend_pool_name = "default"

        accepted_protocols = ["Http", "Https"]
        patterns_to_match  = ["/*"]
        frontend_endpoints = ["frontendendpoint"]
        configuration      = "forwarding_configuration"
        # forwarding_configuration
        forwarding_protocol                   = "MatchRequest"
        cache_enabled                         = true
        cache_use_dynamic_compression         = true
        cache_query_parameter_strip_directive = "StripNone"
        # redirect_configuration
        redirect_protocol = "MatchRequest"
        redirect_type     = "Found"
      }
    }
    frontdoor_rules_engine_config = {
      rules = {
        action           = {}
        match_conditions = {}
      }
    }
  }

  # merge custom and default values
  tags = merge(local.default.tags, var.tags)

  frontdoor_firewall_policy = merge(local.default.frontdoor_firewall_policy, var.frontdoor_firewall_policy)
  frontdoor                 = merge(local.default.frontdoor, var.frontdoor)

  # deep merge over merged config and use defaults if no variable is set
  frontdoor_custom_https_configuration = {
    # get all config
    for instance in keys(var.frontdoor_custom_https_configuration) :
    instance => merge(local.default.frontdoor_custom_https_configuration, var.frontdoor_custom_https_configuration[instance])
  }

  frontdoor_firewall_config = {
    # get all config
    for instance in keys(var.frontdoor_firewall_config) :
    instance => merge(local.default.frontdoor_firewall_config, var.frontdoor_firewall_config[instance])
  }

  frontdoor_config = {
    # get frontdoor instance config
    ## frontdoor-00, frontdoor-01
    for instance in keys(var.frontdoor_config) :
    instance => {
      # get all config
      ## backend_pool, frontend_endpoint etc
      for config in keys(local.default.frontdoor_config) :
      config => {
        # merge default values and values from each config instance
        for config_instance in keys(var.frontdoor_config[instance][config]) :
        config_instance => merge(local.default.frontdoor_config[config], var.frontdoor_config[instance][config][config_instance])
      }
    }
  }

  frontdoor_rules_engine = {
    # get all config
    for instance in keys(var.frontdoor_rules_engine) :
    instance => merge(local.default.frontdoor_rules_engine, var.frontdoor_rules_engine[instance])
  }

  frontdoor_rules_engine_config = {
    # get frontdoor_rules_engine instance config
    for instance in keys(var.frontdoor_rules_engine_config) :
    instance => {
      for config in keys(local.default.frontdoor_rules_engine_config) :
      config => {
        for config_instance in keys(var.frontdoor_rules_engine_config[instance][config]) :
        config_instance => merge(local.default.frontdoor_rules_engine_config[config], var.frontdoor_rules_engine_config[instance][config][config_instance])
      }
    }
  }
}
