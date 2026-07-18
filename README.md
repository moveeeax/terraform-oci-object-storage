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
  source = "github.com/cybercapybara/terraform-oci-object-storage"

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
| `versioning`     | Object versioning mode.                                           | `string`      | `"Disabled"`       |    no    |
| `kms_key_id`     | KMS key OCID for encryption. Null uses Oracle-managed encryption.  | `string`      | `null`             |    no    |
| `auto_tiering`   | Auto-tiering setting (`Enabled` or `Disabled`).                   | `string`      | `"Disabled"`       |    no    |
| `freeform_tags`  | Free-form tags applied to the bucket.                             | `map(string)` | `{}`               |    no    |
| `defined_tags`   | Defined tags applied to the bucket, keyed `namespace.key`.        | `map(string)` | `{}`               |    no    |

## Outputs

| Name           | Description                                |
|----------------|--------------------------------------------|
| `id`           | OCID of the bucket.                        |
| `name`         | Name of the bucket.                        |
| `namespace`    | Object Storage namespace of the bucket.    |
| `storage_tier` | Default storage tier of the bucket.        |

## License

[MIT](LICENSE)
