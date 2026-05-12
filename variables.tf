variable "location" {
  description = "Default Azure region for the Managed Redis instance (e.g. canadacentral). Can be overridden per instance via managed_redis.location."
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Tags applied to every Managed Redis resource. Merged with per-instance tags."
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "(Required) 4-character SSC naming prefix composed of dept(2)+env(1)+region(1), e.g. ScPc = SSC Production Canada Central, ScDc = SSC Development Canada Central. See SSC Azure Naming Standard v2.1."
  type        = string
}

variable "userDefinedString" {
  description = "(Required) User-defined portion of the resource name following the SSC naming convention. Up to 7 characters are used. May include hyphens for sub-field separation (e.g. Core-MRZ)."
  type        = string
}

variable "serverType" {
  description = "3-character SSC SACM device type appended directly to the env prefix before the hyphen. Defaults to CPS (Cloud Platform Service — correct code for generic PaaS / Managed Redis). Override with a more specific code if your org defines one."
  type        = string
  default     = "CPS"
}

variable "managed_redis" {
  description = "Configuration object for a Managed Redis fleet: a shared resource_group/location default, a map of instances (Redis nodes each with sku_name and optional default_database/identity/customer_managed_key), and an optional map of geo_replication_groups linking instances by key."
  type        = any
  default     = {}
}

variable "resource_groups" {
  description = "(Required) Map of resource group objects. Must include the resource group the Managed Redis instance is deployed into."
  type        = any
  default     = {}
}
