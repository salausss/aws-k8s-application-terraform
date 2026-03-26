variable "project_name" {
  description = "Name of the project"
}
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Controls how you are charged: PROVISIONED or PAY_PER_REQUEST"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "The number of read units for this table. Only used if billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "The number of write units for this table. Only used if billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "hash_key" {
  description = "The attribute to use as the partition key"
  type        = string
}

variable "range_key" {
  description = "The attribute to use as the sort key (optional)"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions"
  type        = list(map(string))
}

variable "ttl_enabled" {
  type    = bool
  default = false
}

variable "ttl_attribute" {
  type    = string
  default = "TimeToLive"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "pitr_enabled" {
  type    = bool
  default = false
}