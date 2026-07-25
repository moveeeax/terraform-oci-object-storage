# terraform-oci-object-storage

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Object Storage bucket, with configurable public access, storage tier, versioning,
auto-tiering and optional KMS encryption.

## Usage

```hcl
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

module "bucket" {
  source = "github.com/moveeeax/terraform-oci-object-storage"

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

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                        | Type          | Default            | Required |
|------------------|--------------------------------------------------------------------|---------------|--------------------|:--------:|
| `compartment_id` | OCID of the compartment in which to create the bucket.             | `string`      | n/a                |   yes    |
| `namespace`      | Object Storage namespace for the tenancy.                          | `string`      | n/a                |   yes    |
| `name`           | Name of the bucket (unique within the namespace).                 | `string`      | n/a                |   yes    |
| `access_type`    | Public access type for the bucket.                                | `string`      | `"NoPublicAccess"` |    no    |
| `storage_tier`   | Default storage tier (`Standard` or `Archive`).                   | `string`      | `"Standard"`       |    no    |
| `versioning`     | Object versioning mode (`Enabled`, `Disabled` or `Suspended`).     | `string`      | `"Disabled"`       |    no    |
| `kms_key_id`     | KMS key OCID for encryption. Null uses Oracle-managed encryption.  | `string`      | `null`             |    no    |
| `auto_tiering`   | Auto-tiering setting (`Disabled` or `InfrequentAccess`).           | `string`      | `"Disabled"`       |    no    |
| `freeform_tags`  | Free-form tags applied to the bucket.                             | `map(string)` | `{}`               |    no    |
| `defined_tags`   | Defined tags applied to the bucket, keyed `namespace.key`.        | `map(string)` | `{}`               |    no    |

### Notes on values

- `auto_tiering` is turned on with `InfrequentAccess`, not `Enabled` — the Object
  Storage API only accepts `Disabled` and `InfrequentAccess`.
- `versioning` accepts `Enabled` or `Disabled` at bucket creation and `Enabled` or
  `Suspended` on update. Once versioning has been enabled it cannot be returned to
  `Disabled`, so switching back requires `Suspended`.
- `storage_tier` is immutable; changing it replaces the bucket.

## Outputs

| Name           | Description                                |
|----------------|--------------------------------------------|
| `id`           | OCID of the bucket.                        |
| `name`         | Name of the bucket.                        |
| `namespace`    | Object Storage namespace of the bucket.    |
| `storage_tier` | Default storage tier of the bucket.        |

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
