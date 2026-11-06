variable "compartment_id" {
  description = "OCID of the compartment in which to create the bucket. The tenancy OCID is accepted, since the root compartment is identified by it."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment OCID (\"ocid1.compartment....\") or, for the root compartment, the tenancy OCID (\"ocid1.tenancy....\")."
  }
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

  validation {
    condition     = var.kms_key_id == null || can(regex("^ocid1\\.key\\.", var.kms_key_id))
    error_message = "kms_key_id must be a KMS key OCID (\"ocid1.key....\") or null."
  }
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

variable "retention_rules" {
  description = <<-EOT
    Retention rules (WORM) for the bucket. Each rule needs a unique
    display_name. Set time_amount and time_unit ("DAYS" or "YEARS") for a
    time-bound rule; leave both null for an indefinite rule, which keeps every
    object until the rule is removed.

    time_rule_locked (RFC 3339, e.g. "2027-01-01T00:00:00Z") locks a
    time-bound rule from that moment. Object Storage requires the lock time to
    be at least 14 days in the future, and indefinite rules cannot be locked.
    WARNING: once locked, a rule can only be removed by deleting the bucket,
    and only increases of its duration are allowed.

    Retention rules cannot be added while versioning is "Enabled". At most 100
    rules per bucket.
  EOT
  type = list(object({
    display_name     = string
    time_amount      = optional(number)
    time_unit        = optional(string)
    time_rule_locked = optional(string)
  }))
  default  = []
  nullable = false

  validation {
    condition     = length(var.retention_rules) <= 100
    error_message = "retention_rules supports at most 100 rules per bucket."
  }

  validation {
    condition     = length(distinct([for r in var.retention_rules : r.display_name])) == length(var.retention_rules)
    error_message = "Each retention rule must have a unique display_name."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : try(trimspace(r.display_name) != "", false)])
    error_message = "Each retention rule needs a non-empty display_name."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : (r.time_amount == null) == (r.time_unit == null)])
    error_message = "Set time_amount and time_unit together for a time-bound rule, or leave both null for an indefinite rule."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : r.time_unit == null || contains(["DAYS", "YEARS"], coalesce(r.time_unit, "-"))])
    error_message = "time_unit must be DAYS or YEARS."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : r.time_amount == null || try(r.time_amount >= 1 && floor(r.time_amount) == r.time_amount, false)])
    error_message = "time_amount must be a whole number of at least 1."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : r.time_rule_locked == null || r.time_amount != null])
    error_message = "time_rule_locked can only be set on a time-bound rule (with time_amount and time_unit); indefinite rules cannot be locked."
  }

  validation {
    condition     = alltrue([for r in var.retention_rules : r.time_rule_locked == null || can(formatdate("YYYY", coalesce(r.time_rule_locked, "-")))])
    error_message = "time_rule_locked must be an RFC 3339 timestamp, for example \"2027-01-01T00:00:00Z\"."
  }
}
