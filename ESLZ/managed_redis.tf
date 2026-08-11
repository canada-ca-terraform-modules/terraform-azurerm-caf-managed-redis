# ESLZ/managed_redis.tf
#
# L2 blueprint interface — callers copy this file into their blueprint.
# Each key in var.managed_redis creates one Managed Redis instance
# (cluster + optional default database).
#
# How to determine the source ref:
#   git tag --sort=-v:refname | head -1  → current latest tag
#   Increment: patch (+0.0.1) for bug-fix-only PRs, minor (+0.1.0) for new args

terraform {
  required_version = ">= 1.9"
}

# ── Standard variables ─────────────────────────────────────────────────────────

variable "managed_redis" {
  description = "Map of Managed Redis configuration objects, keyed by instance name (becomes userDefinedString). Each entry deploys one Managed Redis cluster with an optional default database."
  type        = any
  default     = {}
}

variable "resource_groups" {
  description = "Map of resource group objects (must include the RG the Managed Redis instance is deployed into)."
  type        = any
  default     = {}
}

variable "env" {
  description = "Environment prefix used in resource naming (e.g. Dev, Prod)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every Managed Redis resource."
  type        = map(string)
  default     = {}
}

# ── Module block ───────────────────────────────────────────────────────────────

module "managed_redis" {
  source   = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-managed-redis?ref=v1.2.0"
  for_each = var.managed_redis

  resource_groups   = var.resource_groups
  env               = var.env
  userDefinedString = each.key
  tags              = var.tags

  managed_redis = each.value
}
