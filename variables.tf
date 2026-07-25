variable "compartment_id" {
  description = "OCID of the compartment in which to create the bucket."
  type        = string
}

variable "namespace" {
  description = "Object Storage namespace for the tenancy."
  type        = string
}

variable "name" {
  description = "Name of the bucket (unique within the namespace)."
  type        = string
}

variable "access_type" {
  description = "Public access type for the bucket."
  type        = string
  default     = "NoPublicAccess"

  validation {
    condition     = contains(["NoPublicAccess", "ObjectRead", "ObjectReadWithoutList"], var.access_type)
    error_message = "access_type must be NoPublicAccess, ObjectRead, or ObjectReadWithoutList."
  }
}

variable "storage_tier" {
  description = "Default storage tier for the bucket."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Archive"], var.storage_tier)
    error_message = "storage_tier must be Standard or Archive."
  }
}

variable "versioning" {
  description = <<-EOT
    Object versioning mode for the bucket. The Object Storage API accepts only
    "Enabled" or "Disabled" when creating a bucket, and only "Enabled" or
    "Suspended" when updating one — versioning cannot be returned to "Disabled"
    once it has been enabled.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled", "Suspended"], var.versioning)
    error_message = "versioning must be Enabled, Disabled, or Suspended."
  }
}

variable "kms_key_id" {
  description = "OCID of the KMS key used to encrypt objects. Null uses Oracle-managed encryption."
  type        = string
  default     = null
}

variable "auto_tiering" {
  description = <<-EOT
    Auto-tiering setting for the bucket. "InfrequentAccess" transitions objects
    automatically between the Standard and InfrequentAccess tiers based on access
    patterns; "Disabled" turns auto-tiering off. Note that "Enabled" is not a
    valid value in the Object Storage API.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "InfrequentAccess"], var.auto_tiering)
    error_message = "auto_tiering must be Disabled or InfrequentAccess."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the bucket."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the bucket, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
