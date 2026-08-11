# ── Managed Redis instances (nodes) ──────────────────────────────────────────
# Each key in managed_redis.instances creates one Managed Redis cluster.
# Auto-name: {base-name}-{instance_key}; override with instance.instance_name.
resource "azurerm_managed_redis" "instances" {
  for_each = local.instances

  name                = each.value._name
  resource_group_name = each.value._resource_group_name
  location            = each.value._location
  sku_name            = each.value.sku_name

  # Defaults to true; changing forces a new resource
  high_availability_enabled = try(each.value.high_availability_enabled, true)

  # Defaults to "Enabled" when omitted (provider default)
  public_network_access = try(each.value.public_network_access, null)

  # ── Default Database (optional) ──────────────────────────────────────────────
  # A Managed Redis instance is not functional without a database.
  # This block is intentionally optional to allow removal/re-creation for troubleshooting.
  # Note: changing clustering_policy, geo_replication_group_name, or modules forces
  # a new database to be created and data will be lost.
  dynamic "default_database" {
    for_each = try(each.value.default_database, null) != null ? [1] : []
    content {
      access_keys_authentication_enabled = try(each.value.default_database.access_keys_authentication_enabled, false)
      client_protocol                    = try(each.value.default_database.client_protocol, "Encrypted")
      clustering_policy                  = try(each.value.default_database.clustering_policy, "OSSCluster")
      eviction_policy                    = try(each.value.default_database.eviction_policy, "VolatileLRU")
      geo_replication_group_name         = try(each.value.default_database.geo_replication_group_name, null)

      # Persistence: only one of the two below may be set, and neither is compatible
      # with geo_replication_group_name (enforced by the provider, not this module).
      persistence_append_only_file_backup_frequency = try(each.value.default_database.persistence_append_only_file_backup_frequency, null)
      persistence_redis_database_backup_frequency   = try(each.value.default_database.persistence_redis_database_backup_frequency, null)

      # Redis modules: RedisBloom, RedisTimeSeries, RediSearch, RedisJSON
      # Only RediSearch and RedisJSON are allowed with geo-replication
      dynamic "module" {
        for_each = try(each.value.default_database.modules, [])
        iterator = db_module
        content {
          name = db_module.value["name"]
          args = try(db_module.value["args"], null)
        }
      }
    }
  }

  # ── Customer Managed Key (optional) ──────────────────────────────────────────
  dynamic "customer_managed_key" {
    for_each = try(each.value.customer_managed_key, null) != null ? [1] : []
    content {
      key_vault_key_id          = each.value.customer_managed_key.key_vault_key_id
      user_assigned_identity_id = each.value.customer_managed_key.user_assigned_identity_id
    }
  }

  # ── Managed Identity (optional) ───────────────────────────────────────────────
  dynamic "identity" {
    for_each = try(each.value.identity, null) != null ? [1] : []
    content {
      type         = each.value.identity.type
      identity_ids = try(each.value.identity.identity_ids, [])
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}))
}

# ── Geo-replication groups ────────────────────────────────────────────────────
# Each group links a primary instance to one or more peer instances by instance key.
# Linking is reciprocal — only ONE azurerm_managed_redis_geo_replication per group
# is needed. The primary instance's ID is always the anchor; peers are in linked_instances.
#
# Pre-requisites for every instance in a group:
#   - default_database.geo_replication_group_name must be the same value across all members
#   - SKU must be Balanced_B3 or higher
#   - Only RediSearch and RedisJSON modules are compatible with geo-replication
#   - Linking discards cache data and causes a temporary outage
#   - Maximum 4 linked_instances (group of 5 total including primary)
resource "azurerm_managed_redis_geo_replication" "groups" {
  for_each = local.geo_replication_groups

  managed_redis_id = azurerm_managed_redis.instances[each.value.primary_instance].id

  linked_managed_redis_ids = [
    for inst_key in each.value.linked_instances :
    azurerm_managed_redis.instances[inst_key].id
  ]
}
