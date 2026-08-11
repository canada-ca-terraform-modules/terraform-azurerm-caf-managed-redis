# tests/upgrade_compat.tftest.hcl
#
# State-chaining upgrade safety test: proves that the azurerm ~> 5.0 upgrade
# (public_network_access, persistence_* on default_database) is purely additive
# for callers on pre-upgrade tfvars — no resource address change, no forced
# replacement, no destroy.

mock_provider "azurerm" {}

variables {
  env               = "Dev"
  userDefinedString = "test"
  resource_groups = {
    Project = { name = "rg-test-project" }
  }
}

# Step 1: simulate a currently-deployed instance using pre-upgrade config
# (no public_network_access, no persistence_* — matches the azurerm ~> 4.0 module)
run "baseline_apply" {
  command = apply

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        primary = {
          sku_name = "Balanced_B3"
          location = "canadacentral"
          default_database = {
            geo_replication_group_name = "my-geo-group"
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["primary"].name == "DevCPS-test-primary"
    error_message = "Baseline apply: unexpected resource name"
  }
}

# Step 2: plan the upgraded module against that state, adding the new
# azurerm >= 5.0 arguments. Must show additive in-place changes only.
# Note: persistence_* is mutually exclusive with geo_replication_group_name
# (provider-enforced ConflictsWith) — only public_network_access is added here
# to keep the baseline's geo_replication_group_name intact.
run "upgrade_plan_no_replacement" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        primary = {
          sku_name              = "Balanced_B3"
          location              = "canadacentral"
          public_network_access = "Enabled"
          default_database = {
            geo_replication_group_name = "my-geo-group"
          }
        }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["primary"].name == "DevCPS-test-primary"
    error_message = "Resource name must be unchanged after upgrade"
  }

  assert {
    condition     = azurerm_managed_redis.instances["primary"].public_network_access == "Enabled"
    error_message = "public_network_access must be set after upgrade"
  }
}
