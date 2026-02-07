# Quick Start

## Step 1: Bootstrap backend

```bash
cd bootstrap-backend
terraform init
terraform apply -var="bucket_name=YOUR_UNIQUE_TFSTATE_BUCKET" -var="dynamodb_table_name=YOUR_TFSTATE_LOCKS" -var="region=us-west-2"
```

Note the outputs: `bucket_name`, `dynamodb_table_name`, `region`.

## Step 2: Configure root backend

Edit root `backend.tf`: replace `REPLACE_ME` with `bucket_name`, replace the second `REPLACE_ME` with `dynamodb_table_name`, replace `REPLACE_ME_REGION` with `region` (e.g. us-west-2).

Then:

```bash
cd ..
terraform init -reconfigure
```

## Step 3: Apply

```bash
cp terraform.tfvars.example terraform.tfvars
# If create_db = true, set db_password in terraform.tfvars (or -var="db_password=...")
terraform plan
terraform apply
```

## Step 4: Configure kubeconfig

```bash
aws eks update-kubeconfig --region <aws_region> --name <eks_cluster_name>
```

Example: `aws eks update-kubeconfig --region us-west-2 --name final-project-eks`

## Step 5: Check namespaces

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

## Step 6: Port-forward

- Jenkins: `kubectl port-forward svc/jenkins 8080:8080 -n jenkins` (then open http://localhost:8080)
- Argo CD: `kubectl port-forward svc/argocd-server 8081:443 -n argocd` (then open https://localhost:8081)
- Grafana: `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring` (then open http://localhost:3000)

## Destroy

Run `terraform destroy`. If dependencies fail, destroy in order: delete EKS node group and cluster, then RDS, then VPC. Do not run destroy on bootstrap-backend unless you have migrated or discarded state.
