locals {
  # Default resource group — used when an instance does not specify its own.
  # Accepts a full ARM ID or a key into var.resource_groups.
  # Wrapped in try() so callers that always specify per-instance resource_group
  # are not forced to set a fleet-level default.
  default_resource_group_name = try(
    strcontains(var.managed_redis.resource_group, "/resourceGroups/") ? regex("[^/]+$", var.managed_redis.resource_group) : var.resource_groups[var.managed_redis.resource_group].name,
    null
  )

  # Default location — per-instance location overrides this.
  default_location = try(var.managed_redis.location, var.location)

  # Instances (Redis nodes) — enriched with computed name, resolved resource group, and location.
  # Auto-name per instance: {base-name}-{instance_key}; override with instance.instance_name.
  # Resource group resolution order: instance.resource_group → fleet default → error.
  instances = {
    for ik, inst in try(var.managed_redis.instances, {}) :
    ik => merge(inst, {
      _name = try(
        trimspace(inst.instance_name) != "" ? trimspace(inst.instance_name) : "${local.base-name}-${ik}",
        "${local.base-name}-${ik}"
      )
      _resource_group_name = try(
        strcontains(inst.resource_group, "/resourceGroups/") ? regex("[^/]+$", inst.resource_group) : var.resource_groups[inst.resource_group].name,
        local.default_resource_group_name
      )
      _location = try(inst.location, local.default_location)
    })
  }

  # Geo-replication groups — each group links a primary instance to N peer instances.
  # References instance keys defined in managed_redis.instances above.
  # Keys are user-defined group names (e.g. "group-a").
  geo_replication_groups = try(var.managed_redis.geo_replication_groups, {})
}
