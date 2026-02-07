# Final Project: Terraform AWS Infrastructure

VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus, Grafana on AWS. Terraform 1.5+ and AWS provider 5.x.

## Structure

- `bootstrap-backend/` - S3 + DynamoDB for state (run first, local backend)
- `modules/s3-backend` - Same resources as module (bootstrap creates them)
- `modules/vpc` - VPC, subnets, NAT
- `modules/ecr` - ECR repository
- `modules/eks` - EKS cluster, node group, OIDC, EBS CSI addon
- `modules/rds` - RDS or Aurora
- `modules/jenkins` - Jenkins (Helm) in namespace jenkins
- `modules/argo_cd` - Argo CD (Helm) in namespace argocd
- `modules/monitoring` - kube-prometheus-stack (Prometheus + Grafana) in namespace monitoring
- `charts/django-app` - Helm chart for Django app
- `Django/` - Django app, Dockerfile, Jenkinsfile, docker-compose

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- kubectl

## Backend

1. Go to [QUICK_START.md](QUICK_START.md) and follow steps 1-2 to bootstrap and configure the S3 backend.
2. Do not create the S3 bucket or DynamoDB table from the root backend config; bootstrap creates them.

## Apply

After backend is configured:

```bash
cp terraform.tfvars.example terraform.tfvars
# Set db_password if create_db = true
terraform init -reconfigure
terraform plan
terraform apply
```

## After apply

1. Configure kubeconfig: `aws eks update-kubeconfig --region <region> --name <eks_cluster_name>`
2. Check namespaces: `kubectl get all -n jenkins`, `kubectl get all -n argocd`, `kubectl get all -n monitoring`
3. Port-forward:
   - Jenkins: `kubectl port-forward svc/jenkins 8080:8080 -n jenkins`
   - Argo CD: `kubectl port-forward svc/argocd-server 8081:443 -n argocd`
   - Grafana: `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring`

## Destroy

Destroy order: remove Helm releases (Jenkins, Argo CD, monitoring), then EKS, then RDS, VPC. Run `terraform destroy`; if it fails, destroy EKS node group and cluster first, then RDS, then VPC. Do not destroy the S3 backend bucket from this project; use bootstrap-backend or delete manually after state is migrated.

## Variables

See `variables.tf`. Sensitive: `db_password` (no default when create_db is true). Key: `gitops_repo_url` for Argo CD (path charts/django-app).
