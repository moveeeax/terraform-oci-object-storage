provider "oci" {}

# Resolve the tenancy Object Storage namespace.
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

module "bucket" {
  source = "../.."

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "example-bucket"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example bucket into."
  type        = string
}

output "bucket_id" {
  value = module.bucket.id
}
