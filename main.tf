resource "oci_objectstorage_bucket" "this" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = var.name

  access_type  = var.access_type
  storage_tier = var.storage_tier
  versioning   = var.versioning
  kms_key_id   = var.kms_key_id
  auto_tiering = var.auto_tiering

  dynamic "retention_rules" {
    for_each = var.retention_rules
    content {
      display_name     = retention_rules.value.display_name
      time_rule_locked = retention_rules.value.time_rule_locked

      dynamic "duration" {
        # A rule without a duration is an indefinite rule.
        for_each = retention_rules.value.time_amount == null ? [] : [retention_rules.value]
        content {
          time_amount = tostring(duration.value.time_amount)
          time_unit   = duration.value.time_unit
        }
      }
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = length(var.retention_rules) == 0 || var.versioning != "Enabled"
      error_message = "retention_rules cannot be used while versioning is \"Enabled\": Object Storage rejects retention rules on a bucket with versioning enabled. Use \"Disabled\" (or \"Suspended\" on an existing bucket)."
    }
  }
}
