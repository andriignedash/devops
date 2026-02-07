terraform {
  backend "s3" {
    bucket         = "andrii-final-tfstate-324352301711"
    key            = "bootstrap/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks-final-324352301711"
    encrypt        = true
  }
}
