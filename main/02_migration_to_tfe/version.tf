/*
config = {
  "bucket" = "s3backend-vt0gcxzxrkm9nj-state-bucket"
  "dynamodb_table" = "s3backend-vt0gcxzxrkm9nj-state-lock"
  "region" = "ap-northeast-2"
  "role_arn" = "arn:aws:iam::960249453675:role/s3backend-vt0gcxzxrkm9nj-tf-assume-role"
}
*/

terraform {
/*
  backend "s3" {
    bucket         = "s3backend-vt0gcxzxrkm9nj-state-bucket"
    key            = "daeung/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    role_arn       = "arn:aws:iam::960249453675:role/s3backend-vt0gcxzxrkm9nj-tf-assume-role"
    dynamodb_table = "s3backend-vt0gcxzxrkm9nj-state-lock"
  }
*/
  backend "remote" {
    organization = "daeungkim"

    workspaces {
      name = "migration"
    }
  }
  required_version = ">= 0.12.26"
}


