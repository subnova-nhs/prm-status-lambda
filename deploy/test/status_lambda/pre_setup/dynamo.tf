resource "aws_dynamodb_table" "process_storage_table" {
  name             = "PROCESS_STORAGE_${upper(var.environment)}"
  billing_mode     = "PROVISIONED"
  read_capacity    = 1
  write_capacity   = 1
  hash_key         = "PROCESS_ID"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute = {
    name = "PROCESS_ID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}
