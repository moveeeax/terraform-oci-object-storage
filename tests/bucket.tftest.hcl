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

run "rejects_non_ocid_compartment_id" {
  command = plan

  variables {
    compartment_id = "my-compartment"
  }

  expect_failures = [var.compartment_id]
}

run "rejects_non_key_kms_key_id" {
  command = plan

  variables {
    kms_key_id = "ocid1.vault.oc1..aaaaaaaaexamplevault"
  }

  expect_failures = [var.kms_key_id]
}

run "no_retention_rules_by_default" {
  command = plan

  assert {
    condition     = length(oci_objectstorage_bucket.this.retention_rules) == 0
    error_message = "the bucket must have no retention rules unless they are requested"
  }
}

# Retention rules are a set with computed members, so the set is only
# known after apply; the mocked provider makes apply safe here.
run "retention_rules_are_passed_through" {
  command = apply

  variables {
    retention_rules = [
      {
        display_name     = "audit-7y"
        time_amount      = 7
        time_unit        = "YEARS"
        time_rule_locked = "2027-01-01T00:00:00Z"
      },
      {
        display_name = "legal-hold"
      },
    ]
  }

  assert {
    condition     = length(oci_objectstorage_bucket.this.retention_rules) == 2
    error_message = "both retention rules must be set on the bucket"
  }

  assert {
    condition = anytrue([
      for r in oci_objectstorage_bucket.this.retention_rules :
      r.display_name == "audit-7y" && r.duration[0].time_amount == "7" && r.duration[0].time_unit == "YEARS" && r.time_rule_locked == "2027-01-01T00:00:00Z"
    ])
    error_message = "the time-bound rule must carry its duration and lock time"
  }

  assert {
    condition = anytrue([
      for r in oci_objectstorage_bucket.this.retention_rules :
      r.display_name == "legal-hold" && length(r.duration) == 0
    ])
    error_message = "a rule without time_amount must be an indefinite rule (no duration block)"
  }

  assert {
    condition     = output.retention_rules["audit-7y"].time_unit == "YEARS" && output.retention_rules["legal-hold"].time_amount == null
    error_message = "the retention_rules output must be keyed by display_name and expose the duration"
  }
}

run "retention_rules_allowed_with_suspended_versioning" {
  command = apply

  variables {
    versioning      = "Suspended"
    retention_rules = [{ display_name = "keep-30d", time_amount = 30, time_unit = "DAYS" }]
  }

  assert {
    condition     = length(oci_objectstorage_bucket.this.retention_rules) == 1
    error_message = "retention rules are allowed while versioning is Suspended"
  }
}

run "rejects_retention_rules_with_versioning_enabled" {
  command = plan

  variables {
    versioning      = "Enabled"
    retention_rules = [{ display_name = "keep-30d", time_amount = 30, time_unit = "DAYS" }]
  }

  expect_failures = [oci_objectstorage_bucket.this]
}

run "rejects_duplicate_retention_rule_names" {
  command = plan

  variables {
    retention_rules = [
      { display_name = "keep", time_amount = 30, time_unit = "DAYS" },
      { display_name = "keep", time_amount = 1, time_unit = "YEARS" },
    ]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_more_than_100_retention_rules" {
  command = plan

  variables {
    retention_rules = [for i in range(101) : { display_name = "rule-${i}", time_amount = 1, time_unit = "DAYS" }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_unknown_retention_time_unit" {
  command = plan

  variables {
    retention_rules = [{ display_name = "keep", time_amount = 6, time_unit = "MONTHS" }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_time_amount_without_unit" {
  command = plan

  variables {
    retention_rules = [{ display_name = "keep", time_amount = 30 }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_non_whole_time_amount" {
  command = plan

  variables {
    retention_rules = [{ display_name = "keep", time_amount = 1.5, time_unit = "YEARS" }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_locked_indefinite_rule" {
  command = plan

  variables {
    retention_rules = [{ display_name = "forever", time_rule_locked = "2027-01-01T00:00:00Z" }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_non_rfc3339_lock_time" {
  command = plan

  variables {
    retention_rules = [{ display_name = "keep", time_amount = 1, time_unit = "YEARS", time_rule_locked = "2027-01-01" }]
  }

  expect_failures = [var.retention_rules]
}

run "rejects_empty_retention_rule_name" {
  command = plan

  variables {
    retention_rules = [{ display_name = " ", time_amount = 1, time_unit = "DAYS" }]
  }

  expect_failures = [var.retention_rules]
}
