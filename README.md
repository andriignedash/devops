# Final Project: AWS Infrastructure with Terraform

Complete DevOps infrastructure on AWS: VPC, EKS, RDS, ECR, Jenkins (CI), Argo CD (CD), Prometheus + Grafana (monitoring). All managed by Terraform.

## Architecture

```
AWS Cloud (eu-central-1)
  VPC (10.0.0.0/16)
    Public Subnets (3 AZs) -> Internet Gateway
    Private Subnets (3 AZs) -> NAT Gateway
      EKS Cluster (final-eks)
        Node Group (t3.medium, 2 nodes)
          Jenkins       (namespace: jenkins)
          Argo CD       (namespace: argocd)
          Prometheus    (namespace: monitoring)
          Grafana       (namespace: monitoring)
      RDS PostgreSQL (private subnets, SG-restricted)
    ECR (django-app repository)
  S3 + DynamoDB (Terraform state backend)
```

## Project Structure

```
.
├── main.tf                  # Root module: wires all child modules
├── backend.tf               # S3 + DynamoDB backend configuration
├── providers.tf             # AWS, Kubernetes, Helm providers
├── variables.tf             # Input variables
├── outputs.tf               # Root outputs (endpoints, commands)
├── eks_wait.tf              # Readiness gate before Helm installs
├── terraform.tfvars.example # Example variable values
├── scripts/
│   ├── env.sh               # Export AWS_PROFILE and verify identity
│   └── apply.sh             # Init + apply wrapper (zsh-safe)
├── bootstrap-backend/       # One-time setup for S3 + DynamoDB
├── modules/
│   ├── s3-backend/          # S3 bucket + DynamoDB table (reusable)
│   ├── vpc/                 # VPC, subnets, NAT, IGW, routes
│   ├── ecr/                 # ECR repository
│   ├── eks/                 # EKS cluster, node group, OIDC, EBS CSI
│   ├── rds/                 # RDS (PostgreSQL/MySQL) or Aurora
│   ├── jenkins/             # Jenkins via Helm (chart 4.6.1)
│   ├── argo_cd/             # Argo CD via Helm + app-of-apps chart
│   └── monitoring/          # kube-prometheus-stack (Prometheus + Grafana)
├── charts/
│   └── django-app/          # Helm chart for Django application
└── Django/
    ├── app/                 # Django project (settings, urls, wsgi)
    ├── Dockerfile           # Production image (python:3.11-slim + gunicorn)
    ├── Jenkinsfile          # CI pipeline: build + push to ECR
    ├── docker-compose.yaml  # Local development
    └── README.md            # App-specific docs
```

## Security

- **VPC**: 3 public + 3 private subnets across AZs; EKS nodes and RDS in private subnets only
- **NAT Gateway**: outbound internet for private subnets (ECR pull, updates)
- **Security Groups**: RDS accepts connections only from EKS cluster SG and VPC CIDR
- **IAM Roles**: separate roles for EKS cluster, node group, and EBS CSI driver (IRSA via OIDC)
- **EKS**: public + private API endpoint; node group with managed AL2 AMI
- **Terraform state**: encrypted S3 bucket + DynamoDB lock table
- **Sensitive values**: `db_password` marked sensitive, not stored in tfvars (passed via `-var` or `TF_VAR_`)

## CI/CD Pipeline

### Jenkins (CI)
- Deployed via Helm in `jenkins` namespace
- Jenkinsfile: builds Docker image, pushes to ECR with build number tag
- Credentials: `aws-region`, `ecr-registry-url`, `ecr-repository-name` (Secret text)

### Argo CD (CD)
- Deployed via Helm in `argocd` namespace
- App-of-apps pattern: `modules/argo_cd/charts/app-of-apps/`
- Watches `charts/django-app/` for Helm value changes, auto-syncs to EKS
- GitOps repo URL configurable via `gitops_repo_url` variable

## Monitoring

- **Prometheus**: scrapes all cluster metrics, service monitors enabled
- **Grafana**: dashboards for cluster health, pod metrics, node metrics
- **Alertmanager**: alert routing (default config)
- **Node Exporter**: DaemonSet on all nodes for host-level metrics
- All deployed via `kube-prometheus-stack` Helm chart in `monitoring` namespace

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI v2 configured (profile `final` or `default`)
- kubectl
- Helm 3

## Quick Start

See [QUICK_START.md](QUICK_START.md) for step-by-step instructions.

Short version:

```bash
# 1. Bootstrap backend (one time)
cd bootstrap-backend && terraform init && terraform apply

# 2. Init root
cd .. && terraform init -reconfigure

# 3. Apply
terraform apply -var-file=terraform.tfvars.example -var='db_password=YourStrongPassword!'

# 4. Connect to cluster
aws eks update-kubeconfig --region eu-central-1 --name final-eks

# 5. Verify
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

## Access Services

| Service  | Command | URL |
|----------|---------|-----|
| Jenkins  | `kubectl port-forward svc/jenkins 8080:8080 -n jenkins` | http://localhost:8080 |
| Argo CD  | `kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd` | https://localhost:8081 |
| Grafana  | `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring` | http://localhost:3000 |

Default credentials: admin / admin (Jenkins, Grafana). Argo CD initial password: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d`

## Destroy

```bash
terraform destroy -var-file=terraform.tfvars.example -var='db_password=any'
```

If dependencies fail, destroy in order: Helm releases, EKS node group/cluster, RDS, VPC. Do not destroy `bootstrap-backend` unless you have migrated state.

## Variables

See `variables.tf` for all available inputs. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `eu-central-1` |
| `aws_profile` | AWS CLI profile | `final` |
| `eks_cluster_name` | EKS cluster name | `final-project-eks` |
| `eks_node_instance_types` | Node instance types | `["t3.medium"]` |
| `eks_node_desired_size` | Desired node count | `2` |
| `create_db` | Create RDS instance | `false` |
| `db_password` | DB password (sensitive) | `""` |
| `gitops_repo_url` | Argo CD GitOps repo | (set to your repo) |
