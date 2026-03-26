resource "aws_dynamodb_table" "db" {
  name           = "${var.project_name}-${var.table_name}"
  billing_mode   = var.billing_mode
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key       = var.hash_key
  range_key      = var.range_key

  # Dynamic block to handle multiple attributes defined in variables
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  ttl {
    attribute_name = var.ttl_attribute
    enabled        = var.ttl_enabled
  }

  point_in_time_recovery {
    enabled = var.pitr_enabled
  }
}