# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group: writing into
# a shared RG usually requires elevated, non-sandbox permissions. A dedicated
# throwaway RG here needs only Contributor on the sandbox subscription and
# can never collide with or affect any production resource.
#
# terraform-azurerm-caf-managed-redis does not consume a virtual_network/
# subnet directly (no private_endpoint child module) - no vnet dependency is
# created here.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group (or, via the module's own
  # name-derived naming, the same Managed Redis instance name).
  name     = "${var.env}-caf-managed-redis-live-test-${var.pr_number}-rg"
  location = var.location

  # pr-number tag (ticket 13): lets the nightly orphan sweeper find this RG
  # by tag and match it back to a PR, independent of naming convention.
  # repository tag: the sandbox subscription is shared across module repos
  # (ticket 03), so the sweeper must scope its `pr-number` matches to only
  # this repo's own PRs - otherwise a PR number collision across repos could
  # misclassify (or destroy) another repo's live resource group.
  tags = {
    "pr-number"  = var.pr_number
    "repository" = var.repository
  }
}

locals {
  # terraform-azurerm-caf-managed-redis expects resource_groups as a
  # purpose-keyed map (var.managed_redis.resource_group / each instance's
  # own resource_group is a key into this map, not a flat object).
  resource_groups = {
    Project = { name = azurerm_resource_group.live_test.name }
  }
}
