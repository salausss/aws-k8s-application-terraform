variable "project_name" {
  type = string
}

variable "table_name" {
  type        = string
  description = "Name of the table"
}

variable "hash_key" {
  type        = string
  description = "The partition key attribute name"
}

variable "range_key" {
  type        = string
  default     = null
  description = "The sort key attribute name (optional)"
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "List of nested attribute definitions. Only required for hash_key, range_key, and index keys."
}

variable "global_secondary_indexes" {
  type = list(object({
    name               = string
    hash_key           = string
    range_key          = string
    projection_type    = string
    non_key_attributes = list(string)
  }))
  default     = []
  description = "List of GSI definitions"
}

variable "pitr_enabled" {
  type        = bool
  default     = false
  description = "Enable Point-in-Time Recovery"
}

variable "tags" {
  type    = map(string)
  default = {}
}