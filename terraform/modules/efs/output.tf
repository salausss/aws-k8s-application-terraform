output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "efs_csi_role_arn" {
  value = aws_iam_role.efs_csi.arn
}