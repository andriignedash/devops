terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "REPLACE_ME"
    key            = "final-project/terraform.tfstate"
    dynamodb_table = "REPLACE_ME"
    region         = "REPLACE_ME_REGION"
    encrypt        = true
  }
}
# Replace REPLACE_ME / REPLACE_ME_REGION with outputs from bootstrap-backend (bucket_name, dynamodb_table_name, region)
