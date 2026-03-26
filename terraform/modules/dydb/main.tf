resource "aws_dynamodb_table" "betterment_table" {
  name         = "${var.project_name}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Dynamically create attributes based on the input list
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Dynamically create GSIs only if they are defined in the variable
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
    }
  }

  point_in_time_recovery {
    enabled = var.pitr_enabled
  }

  server_side_encryption {
    enabled = true # Default AWS Owned Key
  }
}