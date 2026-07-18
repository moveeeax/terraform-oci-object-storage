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
