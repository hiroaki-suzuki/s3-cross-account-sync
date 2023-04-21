output "s3_sync_role_arn" {
  value       = aws_iam_role.s3_sync_role.arn
  description = "s3 sync を実行するためのIAMロールのARN"
}
