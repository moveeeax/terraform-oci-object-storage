output "id" {
  description = "OCID of the bucket."
  value       = oci_objectstorage_bucket.this.bucket_id
}

output "name" {
  description = "Name of the bucket."
  value       = oci_objectstorage_bucket.this.name
}

output "namespace" {
  description = "Object Storage namespace of the bucket."
  value       = oci_objectstorage_bucket.this.namespace
}

output "storage_tier" {
  description = "Default storage tier of the bucket."
  value       = oci_objectstorage_bucket.this.storage_tier
}

output "retention_rules" {
  description = "Retention rules on the bucket, keyed by display_name: retention_rule_id, time_amount, time_unit and time_rule_locked (null where not set)."
  value = {
    for r in oci_objectstorage_bucket.this.retention_rules : r.display_name => {
      retention_rule_id = r.retention_rule_id
      time_amount       = length(r.duration) > 0 ? r.duration[0].time_amount : null
      time_unit         = length(r.duration) > 0 ? r.duration[0].time_unit : null
      time_rule_locked  = r.time_rule_locked
    }
  }
}
