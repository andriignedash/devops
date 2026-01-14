terraform {
  backend "s3" {
    bucket         = "andrii-gnedash-lesson-5-tfstate-001"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

