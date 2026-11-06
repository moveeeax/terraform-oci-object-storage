# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `retention_rules` input (default `[]`) for WORM retention on the bucket:
  time-bound (`DAYS`/`YEARS`) or indefinite rules, with optional
  `time_rule_locked`. Validated for unique names, at most 100 rules, whole
  positive durations, RFC 3339 lock times and no lock on indefinite rules; the
  plan fails if retention rules are combined with `versioning = "Enabled"`.
- `retention_rules` output, keyed by rule `display_name`.

[Unreleased]: https://github.com/moveeeax/terraform-oci-object-storage/compare/v1.1.0...HEAD
