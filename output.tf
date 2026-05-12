output "instances" {
  description = "Map of all Managed Redis instance objects, keyed by instance key. Sensitive because instances may expose access keys."
  value       = azurerm_managed_redis.instances
  sensitive   = true
}

output "instance_ids" {
  description = "Map of Managed Redis resource IDs, keyed by instance key."
  value       = { for k, v in azurerm_managed_redis.instances : k => v.id }
}

output "instance_names" {
  description = "Map of Managed Redis resource names, keyed by instance key."
  value       = { for k, v in azurerm_managed_redis.instances : k => v.name }
}

output "instance_hostnames" {
  description = "Map of Managed Redis cluster endpoint hostnames, keyed by instance key."
  value       = { for k, v in azurerm_managed_redis.instances : k => v.hostname }
}

output "geo_replication_ids" {
  description = "Map of Managed Redis Geo-Replication resource IDs, keyed by group name. Empty map if no geo_replication_groups are configured."
  value       = { for k, v in azurerm_managed_redis_geo_replication.groups : k => v.id }
}
