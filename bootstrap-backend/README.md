# Bootstrap Backend

Creates the S3 bucket and DynamoDB table for Terraform remote state. Uses local backend (no backend.tf here).

## Steps

1. cd bootstrap-backend
2. terraform init && terraform apply
3. Copy the outputs (bucket_name, dynamodb_table_name, region) into the root `backend.tf`: set `bucket`, `dynamodb_table`, and `region` accordingly.
4. cd .. and run terraform init -reconfigure

After that, the root project will use the remote backend.
