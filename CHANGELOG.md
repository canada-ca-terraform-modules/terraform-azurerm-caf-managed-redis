# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [v1.2.0] - 2026-08-11

### Changed

- **Breaking (provider only, not config):** `azurerm` provider constraint bumped from `~> 4.0` to `~> 5.0` in [providers.tf](providers.tf). No existing `managed_redis` tfvars require changes — all azurerm 5.0 schema for `azurerm_managed_redis` and `azurerm_managed_redis_geo_replication` is unchanged from 4.x for the arguments this module already exposed.
- `ESLZ/managed_redis.tf` module ref bumped to `?ref=v1.2.0`.
- GitHub Actions pins refreshed: `actions/checkout@v7.0.1`, `hashicorp/setup-terraform@v4.0.1`, `terraform-linters/setup-tflint@v6.3.0`, `terraform-docs/gh-actions@v1.4.1` (unchanged, already current).

### Added

- `azurerm_managed_redis.instances`: new optional `public_network_access` argument (Gap analysis vs. azurerm 5.0.1 docs — provider supports it, module did not expose it). Defaults to `null` (provider default `Enabled`) when omitted.
- `azurerm_managed_redis.instances.default_database`: new optional `persistence_append_only_file_backup_frequency` and `persistence_redis_database_backup_frequency` arguments. Mutually exclusive with each other and with `geo_replication_group_name` (enforced by the provider, not this module).
- `.github/workflows/release.yml`: creates a GitHub release on merge to `main`, tagged with the version pinned in `ESLZ/managed_redis.tf`'s own `?ref=`. Idempotent.
- `tests/upgrade_compat.tftest.hcl`: state-chaining test proving the azurerm 5.0 upgrade is additive-only for existing callers (no resource replacement).
- `tests/managed_redis.tftest.hcl`: added `public_network_access_default`, `public_network_access_disabled`, `database_persistence_aof`, `database_persistence_rdb` runs.
- Commented tfvars examples for `public_network_access` and the persistence arguments in [ESLZ/managed_redis.tfvars](ESLZ/managed_redis.tfvars).

### Notes

- No resources were renamed, removed, or had a naming-convention change — no `moved` blocks required.
- `azurerm_managed_redis_geo_replication` schema (`managed_redis_id`, `linked_managed_redis_ids`) is unchanged between 4.x and 5.0.1 — no code changes to that resource.

## [v1.1.0] - prior release

- terraform-docs automation.

## [v1.0.0] - prior release

- Initial module scaffold for `azurerm_managed_redis`.
