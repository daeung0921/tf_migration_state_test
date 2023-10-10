output "config" {
  description = "Terraform Remote backend resources"
  value = {
    bucket         = var.create ? aws_s3_bucket.s3_bucket[0].bucket : null
    region         = data.aws_region.current.name
    role_arn       = var.create ? aws_iam_role.iam_role[0].arn : null
    dynamodb_table = var.create ? aws_dynamodb_table.dynamodb_table[0].name : null
  }
}