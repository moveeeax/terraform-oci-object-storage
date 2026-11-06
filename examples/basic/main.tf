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

# A WORM bucket for audit logs: objects cannot be changed or deleted for a
# year. Retention rules need versioning off (the module default).
module "audit_bucket" {
  source = "../.."

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "example-audit-logs"

  retention_rules = [
    {
      display_name = "audit-1y"
      time_amount  = 1
      time_unit    = "YEARS"
      # Uncomment to lock the rule. Once locked it can only be removed by
      # deleting the bucket; the lock time must be at least 14 days ahead.
      # time_rule_locked = "2027-01-01T00:00:00Z"
    },
  ]
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example bucket into."
  type        = string
}

output "bucket_id" {
  value = module.bucket.id
}

output "audit_bucket_retention_rules" {
  value = module.audit_bucket.retention_rules
}
