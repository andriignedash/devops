terraform {
  backend "s3" {
    bucket         = "andrii-gnedash-lesson-7-tfstate-001"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson-7"
    encrypt        = true
  }
}

