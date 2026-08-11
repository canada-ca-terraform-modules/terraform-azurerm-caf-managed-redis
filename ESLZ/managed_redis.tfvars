# ESLZ/managed_redis.tfvars
#
# Populate this file and copy ESLZ/managed_redis.tf into your L2 blueprint.
# Each top-level key in managed_redis is a "fleet" — one module call that manages
# a set of related Redis instances (nodes) and their geo-replication wiring.
# The key becomes userDefinedString (up to 7 chars used in auto-generated names).

managed_redis = {
  # ── Example: single instance, no geo-replication ─────────────────────────────
  # Minimal deployment — one Redis cluster with a default database.
  # Auto-generated name: ScDcCPS-simple-node  (env=ScDc, serverType=CPS, userDefinedString=simple, key=node)
  # SSC format:          <dept(2)><env(1)><region(1)><deviceType(3)>-<userDefined>-<instance_key>
  simple = {
    resource_group = "Project"
    instances = {
      node = {
        sku_name         = "Balanced_B1"
        location         = "canadacentral"
        default_database = {}
      }
    }
  }

  # ── Example: two nodes with geo-replication ──────────────────────────────────
  # This key becomes userDefinedString: names will be ScDcCPS-mycach-primary, etc.
  # (env=ScDc = SSC Development Canada Central, serverType=CPS = Cloud Platform Service)
  mycache = {
    # ── Default resource group (used by all instances unless overridden) ───────
    resource_group = "Project"

    # ── Optional: default location (used by instances that omit location) ──────
    # location = "canadacentral"

    # ── Instances (Redis nodes) ───────────────────────────────────────────────
    # Each key creates one azurerm_managed_redis resource.
    # Auto-name: {env4}{serverType3}-{userDefinedString7}-{instance_key}
    # Override auto-name with instance_name = "my-exact-name"
    instances = {
      primary = {
        # ── Required ──────────────────────────────────────────────────────────
        # SKU: Balanced_B1/B3/B5/B10/B20/B50/B100/B150/B250/B350/B500/B700/B1000
        #      Flash_F300/F700/F1500
        #      Memory_M10/M20/M50/M100/M150/M200/M250/M350/M500/M700/M1000
        # Balanced_B3 or higher required for geo-replication. Changing forces replace.
        sku_name = "Balanced_B3"
        location = "canadacentral"

        # ── Optional: name override ────────────────────────────────────────────
        # instance_name = "override-exact-name"

        # ── Optional: per-instance resource group override ─────────────────────
        # resource_group = "AnotherRG"

        # ── Optional: high availability (defaults to true; changing forces replace)
        # high_availability_enabled = true

        # ── Optional: public network access (defaults to "Enabled") ────────────
        # public_network_access = "Disabled"

        # ── Optional: default database ────────────────────────────────────────
        # Omit to create the cluster without a database (for troubleshooting only).
        # Note: changing clustering_policy, geo_replication_group_name, or modules
        # forces a new database to be created — data will be lost.
        default_database = {
          # Group name must match across ALL instances to be linked. Changing forces new DB.
          geo_replication_group_name = "my-geo-group"

          # "Encrypted" (default) or "Plaintext"
          # client_protocol = "Encrypted"

          # "OSSCluster" (default) or "EnterpriseCluster"; changing forces new DB (data loss)
          # clustering_policy = "OSSCluster"

          # AllKeysLFU | AllKeysLRU | AllKeysLRandom | VolatileLRU (default) |
          # VolatileLFU | VolatileTTL | VolatileRandom | NoEviction
          # eviction_policy = "VolatileLRU"

          # Defaults to false. Set true to enable access key auth.
          # access_keys_authentication_enabled = false

          # Redis modules — only RediSearch and RedisJSON allowed with geo-replication.
          # Changing module configuration forces new DB (data loss).
          # modules = [
          #   { name = "RediSearch" },
          #   { name = "RedisJSON" },
          #   { name = "RedisBloom",      args = "ERROR_RATE 0.00 INITIAL_SIZE 400" },
          #   { name = "RedisTimeSeries" },
          # ]

          # Persistence — only one of the two below may be set, and neither is
          # compatible with geo_replication_group_name (provider-enforced).
          # persistence_append_only_file_backup_frequency = "1s"
          # persistence_redis_database_backup_frequency    = "1h"
        }

        # ── Optional: managed identity ─────────────────────────────────────────
        # identity = {
        #   # "SystemAssigned", "UserAssigned", or "SystemAssigned, UserAssigned"
        #   type = "SystemAssigned"
        #   # Required when type includes "UserAssigned":
        #   # identity_ids = ["/subscriptions/.../userAssignedIdentities/example"]
        # }

        # ── Optional: customer managed key (requires UserAssigned identity above)
        # customer_managed_key = {
        #   key_vault_key_id          = "https://vault.vault.azure.net/keys/key/version"
        #   user_assigned_identity_id = "/subscriptions/.../userAssignedIdentities/example"
        # }

        # ── Optional: per-instance tags ───────────────────────────────────────
        # tags = { CostCentre = "12345" }
      }

      secondary = {
        sku_name = "Balanced_B3"
        location = "eastus"
        default_database = {
          geo_replication_group_name = "my-geo-group"
        }
      }
    }

    # ── Geo-replication groups (optional) ─────────────────────────────────────
    # Links Redis instances into active geo-replication groups using instance keys.
    # Linking is reciprocal — define ONE group entry per replication group; do NOT
    # add a second entry for the secondary.
    #
    # Pre-requisites:
    #   - All instances in a group must have the SAME geo_replication_group_name
    #   - SKU must be Balanced_B3 or higher on ALL instances
    #   - Only RediSearch and RedisJSON modules are compatible with geo-replication
    #   - Linking causes a temporary outage and discards cache data
    #   - Maximum 4 entries in linked_instances (group of 5 total including primary)
    geo_replication_groups = {
      my-geo-group = {
        # The instance that anchors the azurerm_managed_redis_geo_replication resource
        primary_instance = "primary"
        # Other instance keys to link into this group
        linked_instances = ["secondary"]
      }
    }
  }

  # ── Example: 4 nodes split into 2 independent geo-replication groups ─────────
  # multiregio = {
  #   resource_group = "Project"
  #   instances = {
  #     node-a = { sku_name = "Balanced_B3", location = "canadacentral", default_database = { geo_replication_group_name = "group-a" } }
  #     node-b = { sku_name = "Balanced_B3", location = "eastus",        default_database = { geo_replication_group_name = "group-a" } }
  #     node-c = { sku_name = "Balanced_B3", location = "westeurope",    default_database = { geo_replication_group_name = "group-b" } }
  #     node-d = { sku_name = "Balanced_B3", location = "australiaeast", default_database = { geo_replication_group_name = "group-b" } }
  #   }
  #   geo_replication_groups = {
  #     group-a = { primary_instance = "node-a", linked_instances = ["node-b"] }
  #     group-b = { primary_instance = "node-c", linked_instances = ["node-d"] }
  #   }
  # }
}
