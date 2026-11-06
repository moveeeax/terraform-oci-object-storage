# terraform-oci-object-storage

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Object Storage bucket, with configurable public access, storage tier, versioning,
auto-tiering, retention rules (WORM) and optional KMS encryption.

## Usage

```hcl
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

module "bucket" {
  source = "github.com/moveeeax/terraform-oci-object-storage?ref=v1.0.0"

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "prod-artifacts"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Retention rules (WORM)

```hcl
module "audit_bucket" {
  source = "github.com/moveeeax/terraform-oci-object-storage?ref=v1.2.0"

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "audit-logs"

  retention_rules = [
    {
      display_name     = "audit-7y"
      time_amount      = 7
      time_unit        = "YEARS"
      time_rule_locked = "2027-01-01T00:00:00Z" # locked rules can only be removed by deleting the bucket
    },
    { display_name = "legal-hold" }, # no duration: indefinite rule
  ]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                        | Type          | Default            | Required |
|------------------|--------------------------------------------------------------------|---------------|--------------------|:--------:|
| `compartment_id` | Compartment (or tenancy) OCID in which to create the bucket.       | `string`      | n/a                |   yes    |
| `namespace`      | Object Storage namespace for the tenancy.                          | `string`      | n/a                |   yes    |
| `name`           | Name of the bucket (unique within the namespace).                 | `string`      | n/a                |   yes    |
| `access_type`    | Public access type for the bucket.                                | `string`      | `"NoPublicAccess"` |    no    |
| `storage_tier`   | Default storage tier (`Standard` or `Archive`).                   | `string`      | `"Standard"`       |    no    |
| `versioning`     | `Enabled` or `Disabled` on create; `Suspended` only on an existing bucket. | `string`      | `"Disabled"`       |    no    |
| `kms_key_id`     | KMS key OCID (`ocid1.key.`). Null uses Oracle-managed encryption.  | `string`      | `null`             |    no    |
| `auto_tiering`   | Auto-tiering setting (`Disabled` or `InfrequentAccess`).           | `string`      | `"Disabled"`       |    no    |
| `retention_rules` | Retention rules: `display_name`, optional `time_amount` + `time_unit` (`DAYS`/`YEARS`), optional `time_rule_locked` (RFC 3339). See notes. | `list(object)` | `[]` | no |
| `freeform_tags`  | Free-form tags applied to the bucket.                             | `map(string)` | `{}`               |    no    |
| `defined_tags`   | Defined tags applied to the bucket, keyed `namespace.key`.        | `map(string)` | `{}`               |    no    |

### Notes on values

- `auto_tiering` is turned on with `InfrequentAccess`, not `Enabled` — the Object
  Storage API only accepts `Disabled` and `InfrequentAccess`.
- `versioning` accepts `Enabled` or `Disabled` at bucket creation and `Enabled` or
  `Suspended` on update. Once versioning has been enabled it cannot be returned to
  `Disabled`, so switching back requires `Suspended`.
- `storage_tier` is immutable; changing it replaces the bucket.
- `retention_rules`: a rule with `time_amount` and `time_unit` is time-bound; a rule
  without both is indefinite. Names must be unique, at most 100 rules per bucket.
  Rules cannot be added while `versioning` is `Enabled` (`Suspended` is fine), and
  the module fails the plan on that combination. `time_rule_locked` is allowed only
  on time-bound rules and must be at least 14 days in the future (checked by OCI at
  apply, not by the module). A locked rule can only be removed by deleting the
  bucket, and only increases of its duration are allowed afterwards.
  The provider matches rules by `display_name`, so renaming a rule deletes it and
  creates a new one, which OCI refuses for a locked rule.

## Outputs

| Name           | Description                                |
|----------------|--------------------------------------------|
| `id`           | OCID of the bucket.                        |
| `name`         | Name of the bucket.                        |
| `namespace`    | Object Storage namespace of the bucket.    |
| `storage_tier` | Default storage tier of the bucket.        |
| `retention_rules` | Map keyed by rule `display_name`: `retention_rule_id`, `time_amount`, `time_unit`, `time_rule_locked`. |

## Development

The tests in [`tests/`](tests) mock the OCI provider, so they need no tenancy,
credentials or network access:

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
terraform test          # requires terraform >= 1.7 for provider mocking
tflint --recursive
```

## License

[MIT](LICENSE)
