# tests/managed_redis.tftest.hcl
#
# All tests use mock_provider so no Azure credentials are required.
# Run with: terraform test

mock_provider "azurerm" {}

# ── Shared variables used across most tests ────────────────────────────────────
variables {
  env               = "Dev"
  userDefinedString = "test"
  resource_groups = {
    Project = { name = "rg-test-project" }
  }
}

# ── Naming convention: auto-name is {base-name}-{instance_key} ────────────────
run "naming_convention" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        primary   = { sku_name = "Balanced_B3", location = "canadacentral" }
        secondary = { sku_name = "Balanced_B3", location = "eastus" }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["primary"].name == "DevCPS-test-primary"
    error_message = "Primary instance name must follow {env4}{serverType3}-{userDefinedString7}-{instance_key}"
  }

  assert {
    condition     = azurerm_managed_redis.instances["secondary"].name == "DevCPS-test-secondary"
    error_message = "Secondary instance name must follow {env4}{serverType3}-{userDefinedString7}-{instance_key}"
  }
}

# ── Per-instance name override takes precedence ───────────────────────────────
run "name_override" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        primary = {
          sku_name      = "Balanced_B3"
          location      = "canadacentral"
          instance_name = "my-custom-redis"
        }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["primary"].name == "my-custom-redis"
    error_message = "Explicit instance_name must override auto-generated name"
  }
}

# ── Default values: HA defaults to true, no geo groups created ────────────────
run "default_values" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        solo = { sku_name = "Balanced_B3", location = "canadacentral" }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["solo"].high_availability_enabled == true
    error_message = "high_availability_enabled must default to true"
  }

  assert {
    condition     = length(azurerm_managed_redis.instances["solo"].default_database) == 0
    error_message = "default_database must not be emitted when not configured"
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups) == 0
    error_message = "No geo-replication resources must be created when geo_replication_groups is absent"
  }
}

# ── Four instances created ─────────────────────────────────────────────────────
run "multiple_instances" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        node-a = { sku_name = "Balanced_B3", location = "canadacentral" }
        node-b = { sku_name = "Balanced_B3", location = "eastus" }
        node-c = { sku_name = "Balanced_B3", location = "westeurope" }
        node-d = { sku_name = "Balanced_B3", location = "australiaeast" }
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_redis.instances) == 4
    error_message = "Four Managed Redis instances must be created"
  }
}

# ── Single geo-replication group linking two instances ────────────────────────
run "geo_replication_single_group" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        primary = {
          sku_name         = "Balanced_B3"
          location         = "canadacentral"
          default_database = { geo_replication_group_name = "group-a" }
        }
        secondary = {
          sku_name         = "Balanced_B3"
          location         = "eastus"
          default_database = { geo_replication_group_name = "group-a" }
        }
      }
      geo_replication_groups = {
        group-a = {
          primary_instance = "primary"
          linked_instances = ["secondary"]
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups) == 1
    error_message = "One geo-replication resource must be created"
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups["group-a"].linked_managed_redis_ids) == 1
    error_message = "Group 'group-a' must have one linked instance"
  }
}

# ── Two geo-replication groups across four instances ──────────────────────────
# 4 nodes split into 2 independent geo-replication groups of 2
run "geo_replication_two_groups" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        node-a = { sku_name = "Balanced_B3", location = "canadacentral", default_database = { geo_replication_group_name = "group-a" } }
        node-b = { sku_name = "Balanced_B3", location = "eastus", default_database = { geo_replication_group_name = "group-a" } }
        node-c = { sku_name = "Balanced_B3", location = "westeurope", default_database = { geo_replication_group_name = "group-b" } }
        node-d = { sku_name = "Balanced_B3", location = "australiaeast", default_database = { geo_replication_group_name = "group-b" } }
      }
      geo_replication_groups = {
        group-a = {
          primary_instance = "node-a"
          linked_instances = ["node-b"]
        }
        group-b = {
          primary_instance = "node-c"
          linked_instances = ["node-d"]
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_redis.instances) == 4
    error_message = "Four Managed Redis instances must be created"
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups) == 2
    error_message = "Two geo-replication resources must be created"
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups["group-a"].linked_managed_redis_ids) == 1
    error_message = "Group 'group-a' must have one linked instance"
  }

  assert {
    condition     = length(azurerm_managed_redis_geo_replication.groups["group-b"].linked_managed_redis_ids) == 1
    error_message = "Group 'group-b' must have one linked instance"
  }
}

# ── Per-instance location is applied correctly ────────────────────────────────
run "per_instance_location" {
  command = plan

  variables {
    location = "canadacentral"
    managed_redis = {
      resource_group = "Project"
      instances = {
        local-instance  = { sku_name = "Balanced_B3" }
        remote-instance = { sku_name = "Balanced_B3", location = "westeurope" }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["local-instance"].location == "canadacentral"
    error_message = "Instance without location override must inherit module-level var.location"
  }

  assert {
    condition     = azurerm_managed_redis.instances["remote-instance"].location == "westeurope"
    error_message = "Instance with explicit location must use that location"
  }
}

# ── Module-level and per-instance tags are merged correctly ───────────────────
run "tag_merging" {
  command = plan

  variables {
    tags = { ManagedBy = "Terraform" }
    managed_redis = {
      resource_group = "Project"
      instances = {
        tagged = {
          sku_name = "Balanced_B3"
          location = "canadacentral"
          tags     = { CostCentre = "12345" }
        }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["tagged"].tags["ManagedBy"] == "Terraform"
    error_message = "Module-level tags must appear on the instance"
  }

  assert {
    condition     = azurerm_managed_redis.instances["tagged"].tags["CostCentre"] == "12345"
    error_message = "Per-instance tags must appear on the instance"
  }
}

# ── Default database block is emitted when configured ────────────────────────
run "default_database_config" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        dbnode = {
          sku_name = "Balanced_B3"
          location = "canadacentral"
          default_database = {
            geo_replication_group_name = "myGeoGroup"
            client_protocol            = "Encrypted"
            eviction_policy            = "VolatileLRU"
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_redis.instances["dbnode"].default_database) == 1
    error_message = "default_database block must be emitted when configured"
  }
}

# ── Redis modules in default_database ────────────────────────────────────────
run "database_with_modules" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        modnode = {
          sku_name = "Balanced_B3"
          location = "canadacentral"
          default_database = {
            modules = [
              { name = "RediSearch" },
              { name = "RedisJSON" },
            ]
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_redis.instances["modnode"].default_database[0].module) == 2
    error_message = "Two Redis modules must be configured in the default_database"
  }
}

# ── SystemAssigned identity ───────────────────────────────────────────────────
run "system_assigned_identity" {
  command = plan

  variables {
    managed_redis = {
      resource_group = "Project"
      instances = {
        idnode = {
          sku_name = "Balanced_B3"
          location = "canadacentral"
          identity = { type = "SystemAssigned" }
        }
      }
    }
  }

  assert {
    condition     = azurerm_managed_redis.instances["idnode"].identity[0].type == "SystemAssigned"
    error_message = "Identity type must be SystemAssigned"
  }
}
