resource "oci_objectstorage_bucket" "this" {
  compartment_id = var.compartment_id
  namespace      = var.namespace
  name           = var.name

  access_type  = var.access_type
  storage_tier = var.storage_tier
  versioning   = var.versioning
  kms_key_id   = var.kms_key_id
  auto_tiering = var.auto_tiering

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
