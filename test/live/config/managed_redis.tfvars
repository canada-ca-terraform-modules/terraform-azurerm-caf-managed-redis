# config/managed_redis.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance, not a two-code-path engineered fixture and not a
# dormant "_" template.
#
# This harness deploys into its own throwaway resource group
# (test_dependencies.tf) - no L1 access or shared resource group permissions
# needed, and no risk of colliding with any real resource.
#
# Maintained by whoever adds a new optional input to the module: update this
# file in the same PR if you want live coverage of it, same discipline as
# updating tests/managed_redis.tftest.hcl.

env = "livetest"

managed_redis = {
  resource_group = "Project"

  instances = {
    redis = {
      sku_name = "Balanced_B3"

      default_database = {
        client_protocol   = "Encrypted"
        clustering_policy = "OSSCluster"
        eviction_policy   = "VolatileLRU"
      }
    }
  }
}
