 
module "s3_backend" {
  source            = "../../modules/terraform-aws-s3-backend"
  create            = true 
}
 
output "config" {
  description = "Terraform Remote backend resources"
  value = {
    bucket         = module.s3_backend.config.bucket
    region         =  module.s3_backend.config.region
    role_arn       =  module.s3_backend.config.role_arn
    dynamodb_table = module.s3_backend.config.dynamodb_table
  }
}