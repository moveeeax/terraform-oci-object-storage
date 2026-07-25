# Unit tests for the module's input validation and safe defaults.
#
# The OCI provider is mocked, so these run with no tenancy, credentials or
# network access. Requires Terraform >= 1.7 / OpenTofu >= 1.7 for
# `mock_provider`; the module itself still only requires >= 1.5.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  namespace      = "examplenamespace"
  name           = "example-bucket"
}

run "safe_defaults" {
  command = plan

  assert {
    condition     = oci_objectstorage_bucket.this.access_type == "NoPublicAccess"
    error_message = "bucket must default to NoPublicAccess so objects are not world-readable"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.auto_tiering == "Disabled"
    error_message = "auto_tiering must default to Disabled"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.storage_tier == "Standard"
    error_message = "storage_tier must default to Standard"
  }
}

run "inputs_are_passed_through" {
  command = plan

  variables {
    access_type   = "ObjectReadWithoutList"
    storage_tier  = "Archive"
    versioning    = "Enabled"
    auto_tiering  = "InfrequentAccess"
    kms_key_id    = "ocid1.key.oc1..aaaaaaaaexamplekey"
    freeform_tags = { Environment = "test" }
    defined_tags  = { "Operations.Environment" = "test" }
  }

  assert {
    condition     = oci_objectstorage_bucket.this.access_type == "ObjectReadWithoutList"
    error_message = "access_type was not passed through to the bucket"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.versioning == "Enabled"
    error_message = "versioning was not passed through to the bucket"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.auto_tiering == "InfrequentAccess"
    error_message = "auto_tiering must accept InfrequentAccess, the only value that enables auto-tiering"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.kms_key_id == "ocid1.key.oc1..aaaaaaaaexamplekey"
    error_message = "kms_key_id was not passed through to the bucket"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.freeform_tags["Environment"] == "test"
    error_message = "freeform_tags were not passed through to the bucket"
  }

  assert {
    condition     = oci_objectstorage_bucket.this.defined_tags["Operations.Environment"] == "test"
    error_message = "defined_tags were not passed through to the bucket"
  }
}

# "Enabled" is not a member of the Object Storage auto-tiering enum
# (Disabled | InfrequentAccess); accepting it would defer the failure to apply.
run "rejects_enabled_auto_tiering" {
  command = plan

  variables {
    auto_tiering = "Enabled"
  }

  expect_failures = [var.auto_tiering]
}

run "rejects_unknown_auto_tiering" {
  command = plan

  variables {
    auto_tiering = "Frequent"
  }

  expect_failures = [var.auto_tiering]
}

run "rejects_unknown_access_type" {
  command = plan

  variables {
    access_type = "Public"
  }

  expect_failures = [var.access_type]
}

run "rejects_unknown_storage_tier" {
  command = plan

  variables {
    storage_tier = "Glacier"
  }

  expect_failures = [var.storage_tier]
}

run "rejects_unknown_versioning" {
  command = plan

  variables {
    versioning = "On"
  }

  expect_failures = [var.versioning]
}
