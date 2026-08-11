# terraform-azurerm-caf-managed-redis

Deploys an [Azure Managed Redis](https://learn.microsoft.com/azure/redis/overview) instance (cluster + optional default database) following the SSC Cloud Adoption Framework naming and tagging standard.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.0.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_managed_redis.instances](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis) | resource |
| [azurerm_managed_redis_geo_replication.groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis_geo_replication) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | (Required) 4-character SSC naming prefix composed of dept(2)+env(1)+region(1), e.g. ScPc = SSC Production Canada Central, ScDc = SSC Development Canada Central. See SSC Azure Naming Standard v2.1. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Default Azure region for the Managed Redis instance (e.g. canadacentral). Can be overridden per instance via managed\_redis.location. | `string` | `"canadacentral"` | no |
| <a name="input_managed_redis"></a> [managed\_redis](#input\_managed\_redis) | Configuration object for a Managed Redis fleet: a shared resource\_group/location default, a map of instances (Redis nodes each with sku\_name and optional default\_database/identity/customer\_managed\_key), and an optional map of geo\_replication\_groups linking instances by key. | `any` | `{}` | no |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | (Required) Map of resource group objects. Must include the resource group the Managed Redis instance is deployed into. | `any` | `{}` | no |
| <a name="input_serverType"></a> [serverType](#input\_serverType) | 3-character SSC SACM device type appended directly to the env prefix before the hyphen. Defaults to CPS (Cloud Platform Service — correct code for generic PaaS / Managed Redis). Override with a more specific code if your org defines one. | `string` | `"CPS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to every Managed Redis resource. Merged with per-instance tags. | `map(string)` | `{}` | no |
| <a name="input_userDefinedString"></a> [userDefinedString](#input\_userDefinedString) | (Required) User-defined portion of the resource name following the SSC naming convention. Up to 7 characters are used. May include hyphens for sub-field separation (e.g. Core-MRZ). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_geo_replication_ids"></a> [geo\_replication\_ids](#output\_geo\_replication\_ids) | Map of Managed Redis Geo-Replication resource IDs, keyed by group name. Empty map if no geo\_replication\_groups are configured. |
| <a name="output_instance_hostnames"></a> [instance\_hostnames](#output\_instance\_hostnames) | Map of Managed Redis cluster endpoint hostnames, keyed by instance key. |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | Map of Managed Redis resource IDs, keyed by instance key. |
| <a name="output_instance_names"></a> [instance\_names](#output\_instance\_names) | Map of Managed Redis resource names, keyed by instance key. |
| <a name="output_instances"></a> [instances](#output\_instances) | Map of all Managed Redis instance objects, keyed by instance key. Sensitive because instances may expose access keys. |
<!-- END_TF_DOCS -->
