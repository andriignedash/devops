terraform {
  backend "s3" {
    bucket         = "andrii-gnedash-lesson-8-9-tfstate-001"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-lesson-8-9"
    encrypt        = true
  }
}

