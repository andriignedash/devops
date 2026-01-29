# Lesson 8-9: CI/CD with Jenkins, Argo CD, Helm, Terraform, ECR and EKS

## CI/CD Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                           │
│                                                                       │
│  1. Git Push → GitHub                                                │
│  2. Jenkins Pipeline (EKS Pod with Kaniko)                          │
│     ├─ Checkout Code                                                 │
│     ├─ Build Docker Image (Kaniko - no Docker daemon)               │
│     ├─ Push to ECR (image:tag + image:latest)                       │
│     └─ Update GitOps Repo (values.yaml with new tag)                │
│                                                                       │
│  3. Argo CD (GitOps Controller)                                      │
│     ├─ Detect changes in GitOps repository                          │
│     ├─ Auto Sync (selfHeal + prune)                                 │
│     └─ Deploy to EKS namespace 'django'                             │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      Infrastructure (Terraform)                      │
│                                                                       │
│  AWS Infrastructure:                                                 │
│  ├─ VPC (3 AZ, public/private subnets)                             │
│  ├─ EKS Cluster v1.29 (2-6 nodes t3.medium)                        │
│  ├─ ECR Repository (for Docker images)                             │
│  └─ S3 + DynamoDB (Terraform state backend)                        │
│                                                                       │
│  Kubernetes Apps (Helm via Terraform):                              │
│  ├─ Jenkins (namespace: jenkins)                                    │
│  │  ├─ Controller with JCasC                                       │
│  │  ├─ Kubernetes Cloud Agent (Kaniko pod template)                │
│  │  └─ PVC 10Gi (gp2)                                              │
│  │                                                                   │
│  └─ Argo CD (namespace: argocd)                                     │
│     ├─ Server (insecure mode for simplicity)                       │
│     ├─ Application Controller                                       │
│     ├─ Repository Secret (GitOps repo)                             │
│     └─ Application CR (django-app)                                  │
└─────────────────────────────────────────────────────────────────────┘
```

## Requirements

### Installed Tools

- **AWS CLI** (configured with credentials)
- **Terraform** >= 1.5.0
- **kubectl**
- **Docker** (for local testing, optional)
- **git**
- **jq** (optional, for JSON parsing)

### AWS Resources

- AWS Account with permissions to create:
  - VPC, Subnets, Internet Gateway, NAT Gateway
  - EKS Cluster, Node Groups
  - ECR Repository
  - S3 Bucket, DynamoDB Table
  - IAM Roles and Policies

## Repository Separation

This project uses **two separate repositories** following GitOps best practices:

### Why Two Repositories?

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Repository Separation                            │
│                                                                       │
│  Repo A: devops (Infrastructure + CI)                               │
│  ├─ Terraform modules (VPC, EKS, ECR, Jenkins, Argo CD)            │
│  ├─ Jenkinsfile (CI/CD pipeline)                                    │
│  ├─ Application source code (docker-django-nginx/)                  │
│  └─ Infrastructure documentation                                    │
│                                                                       │
│  Repo B: devops-gitops (GitOps Source of Truth)                     │
│  ├─ Helm charts for application deployment                          │
│  ├─ values.yaml (image tag updated by Jenkins)                      │
│  └─ Kubernetes manifests via Helm templates                         │
│                                                                       │
│  Benefits:                                                           │
│  - Clear separation of concerns (CI vs CD)                          │
│  - Argo CD only watches GitOps repo (security)                      │
│  - Infrastructure changes don't trigger app deploys                 │
│  - Audit trail for application deployments                          │
└─────────────────────────────────────────────────────────────────────┘
```

### CI/CD Flow Between Repositories

```
Developer → Git push (Repo A: devops)
         → Jenkins Pipeline
         → Build Docker image (Kaniko)
         → Push to ECR
         → Git commit (Repo B: devops-gitops)
         → Argo CD detects change
         → Auto-sync to Kubernetes
         → Application deployed/updated
```

### Repository URLs

| Repository | URL | Purpose |
|------------|-----|---------|
| **Repo A** (Infrastructure) | https://github.com/andriignedash/devops | Terraform, Jenkins, Argo CD config, Jenkinsfile |
| **Repo B** (GitOps) | https://github.com/andriignedash/devops-gitops | Helm charts, values.yaml (source of truth) |

## Quick Start

### 1. Repository Setup

#### A) Infrastructure Repository (this repo)

**URL:** https://github.com/andriignedash/devops (branch: `lesson-8-9`)

Contains:
- Terraform infrastructure (`lesson-8-9/`)
- Django application source code (`docker-django-nginx/app/`)
- **Jenkinsfile** (in repository root)
- Jenkins and Argo CD Terraform modules

#### B) GitOps Repository

**URL:** https://github.com/andriignedash/devops-gitops (branch: `main`)

Contains:
```
devops-gitops/
├── README.md
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml          # <-- Jenkins updates image.tag here
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            └── hpa.yaml
```

**Note:** The GitOps repository is already configured. Argo CD is set to watch:
- Repository: `https://github.com/andriignedash/devops-gitops.git`
- Branch: `main`
- Path: `charts/django-app`

### 2. Terraform Backend Bootstrap

The S3 backend and DynamoDB table are created by the same Terraform project they are used to store state for. This creates a chicken-and-egg problem on first run.

**First-time deployment (bootstrap):**

```bash
cd lesson-8-9

# Step 1: Initialize without backend
terraform init -backend=false

# Step 2: Create only the S3 bucket and DynamoDB table
terraform apply -target=module.s3_backend

# Step 3: Re-initialize with the backend now that it exists
terraform init -reconfigure
```

**Subsequent deployments (normal):**

```bash
cd lesson-8-9

terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Deploy Infrastructure

```bash
cd lesson-8-9

terraform init

terraform plan

terraform apply -auto-approve
```

**Execution time:** ~15-20 minutes

**Creates:**
- VPC with 3 availability zones
- EKS cluster with 2 worker nodes
- ECR repository
- Jenkins (namespace: jenkins)
- Argo CD (namespace: argocd)

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --name lesson-8-9-eks --region us-west-2

kubectl get nodes

kubectl get pods -A
```

### 4. Check Outputs

```bash
terraform output

terraform output -raw ecr_repository_url

terraform output -raw jenkins_port_forward

terraform output -raw argocd_port_forward
```

## Jenkins: Setup and Usage

### 1. Open Jenkins UI

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

Open in browser: http://localhost:8080

### 2. Get Admin Password

```bash
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d

echo
```

**Login:** `admin`  
**Password:** (from command above)

### 3. Configure Credentials

#### GitHub Personal Access Token

1. In Jenkins UI: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - **Kind:** Secret text
   - **Secret:** (your GitHub PAT with `repo` scope)
   - **ID:** `github_pat`
   - **Description:** GitHub Personal Access Token

**TODO:** Create GitHub PAT:
- https://github.com/settings/tokens
- Scope: `repo` (full control of private repositories)

#### AWS ECR Credentials (optional)

Kaniko uses Amazon ECR Credential Helper automatically via node IAM role.

**TODO (if IRSA needed):** Configure IRSA for Jenkins pod:
- Create IAM role with `AmazonEC2ContainerRegistryPowerUser` policy
- Add `eks.amazonaws.com/role-arn` annotation to ServiceAccount

### 4. Create Pipeline Job

1. **New Item** → **Pipeline** → name: `django-app-pipeline`
2. **Pipeline**:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** (URL of this repository)
   - **Branch:** `*/lesson-8-9`
   - **Script Path:** `Jenkinsfile`
3. **Save**

### 5. Configure Environment Variables (optional)

In **Configure** → **Pipeline** → **Environment Variables** (via EnvInject or in Jenkinsfile):

```groovy
ECR_REGISTRY=XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com
ECR_REPOSITORY=lesson-8-9-ecr
AWS_REGION=us-west-2
GITOPS_REPO_URL=https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git
GITOPS_BRANCH=main
GITOPS_VALUES_PATH=charts/django-app/values.yaml
```

**TODO:** Update variables in Jenkinsfile or via Jenkins UI.

### 6. Run Pipeline

**Build Now** → Check logs in **Console Output**

**Stages:**
1. **Checkout** - clone repository
2. **Build & Push to ECR** - Kaniko build + push
3. **Update GitOps Repo** - update `values.yaml` with new tag

## Argo CD: Setup and Monitoring

### 1. Open Argo CD UI

```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
```

Open in browser: http://localhost:8081

### 2. Get Admin Password

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

echo
```

**Login:** `admin`  
**Password:** (from command above)

### 3. Check Application

In Argo CD UI:
- **Applications** → `django-app`
- **Status:** Healthy (after first sync)
- **Sync Status:** Synced

**Automatic sync:**
- `prune: true` - removes old resources
- `selfHeal: true` - restores on manual changes
- `CreateNamespace: true` - creates namespace automatically

### 4. Manual Sync (if needed)

```bash
kubectl get applications -n argocd

kubectl get application django-app -n argocd -o yaml

argocd app sync django-app
```

Or via UI: **Sync** → **Synchronize**

### 5. Monitor Updates

After Jenkins updates GitOps repository:

1. Argo CD detects changes (~30 seconds)
2. Auto-sync starts
3. New image is deployed to namespace `django`

**Check:**

```bash
kubectl get pods -n django

kubectl describe deployment -n django django-app

kubectl rollout status deployment/django-app -n django
```

## GitOps Workflow: Full Cycle

### 1. Local Development

```bash
cd docker-django-nginx/app

git checkout -b feature/new-feature

# Make code changes...
```

### 2. Commit and Push

```bash
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
```

### 3. Run Jenkins Pipeline

**In Jenkins:**
- Configure webhook or run pipeline manually
- Pipeline executes:
  - Build image with tag `git-sha-short`
  - Push to ECR: `image:abc1234` + `image:latest`
  - Update GitOps repo: `image.tag: "abc1234"`

**TODO:** Configure GitHub webhook:
- Payload URL: `http://jenkins-external-url/github-webhook/`
- Content type: `application/json`
- Events: Just the push event

### 4. Argo CD Auto-Sync

Argo CD automatically:
1. Detects changes in `values.yaml`
2. Starts sync
3. Updates deployment with new image
4. Kubernetes performs rolling update

### 5. Verify Deployment

```bash
kubectl get pods -n django -w

kubectl logs -n django deployment/django-app -f

kubectl get events -n django --sort-by='.lastTimestamp'
```

### 6. Access Application

```bash
kubectl get svc -n django

export DJANGO_URL=$(kubectl get svc -n django django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$DJANGO_URL
```

## Verification Commands

### EKS Cluster

```bash
kubectl get nodes -o wide

kubectl top nodes

kubectl get namespaces
```

### Jenkins

```bash
kubectl get pods -n jenkins

kubectl logs -n jenkins deployment/jenkins -f

kubectl describe pod -n jenkins <jenkins-pod-name>

kubectl exec -it -n jenkins <jenkins-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Argo CD

```bash
kubectl get pods -n argocd

kubectl get applications -n argocd

kubectl describe application django-app -n argocd

kubectl logs -n argocd deployment/argocd-server -f
```

### Django Application

```bash
kubectl get all -n django

kubectl get pods -n django -o wide

kubectl describe deployment django-app -n django

kubectl logs -n django deployment/django-app --tail=50

kubectl get hpa -n django
```

### ECR

```bash
aws ecr describe-repositories --region us-west-2

aws ecr list-images --repository-name lesson-8-9-ecr --region us-west-2

aws ecr describe-images --repository-name lesson-8-9-ecr --region us-west-2 --output table
```

## Troubleshooting

### Jenkins Not Starting

```bash
kubectl get events -n jenkins --sort-by='.lastTimestamp'

kubectl describe pod -n jenkins <jenkins-pod-name>

kubectl logs -n jenkins <jenkins-pod-name> --previous
```

**Common issues:**
- PVC not created (check storage class)
- Insufficient resources on nodes

### Kaniko Build Fails

**Error:** `error building image: getting stage builder`

**Solution:**
- Check that Dockerfile exists at path
- Verify context path is correct
- Check pod resources (memory, cpu)

**Error:** `error pushing image: denied`

**Solution:**
- Check node IAM role (should have ECR permissions)
- Verify ECR repository URL

### Argo CD Not Syncing

```bash
kubectl logs -n argocd deployment/argocd-application-controller

kubectl get application django-app -n argocd -o yaml | grep -A 10 status
```

**Common issues:**
- GitOps repository unreachable (check Repository Secret)
- Incorrect path to chart
- RBAC issues

### Django App Not Accessible

```bash
kubectl get svc -n django django-app -o wide

kubectl describe svc -n django django-app

kubectl get endpoints -n django
```

**LoadBalancer not getting external IP:**
- Check AWS Load Balancer Controller
- Verify subnet tags for ELB
- Check security groups

## Project Structure

```
lesson-8-9/
├── README.md                    # Detailed documentation (this file)
├── QUICK_START.md               # Quick start guide
├── GITOPS_REPO_EXAMPLE.md       # GitOps repository example
├── backend.tf                   # S3 backend configuration
├── main.tf                      # Main file with modules
├── outputs.tf                   # Terraform outputs
├── .gitignore
│
├── modules/
│   ├── s3-backend/             # S3 + DynamoDB for state
│   ├── vpc/                    # VPC with 3 AZ
│   ├── ecr/                    # ECR repository
│   ├── eks/                    # EKS cluster
│   │
│   ├── jenkins/                # ✨ NEW module
│   │   ├── jenkins.tf         # Helm release + namespace + RBAC
│   │   ├── providers.tf       # Kubernetes + Helm providers
│   │   ├── variables.tf       # Module variables
│   │   ├── outputs.tf         # Outputs (port-forward commands, password)
│   │   └── values.yaml.tpl    # Jenkins values with Kaniko pod template
│   │
│   └── argo_cd/               # ✨ NEW module
│       ├── argo_cd.tf         # Helm releases (argocd + argo-apps)
│       ├── providers.tf       # Kubernetes + Helm providers
│       ├── variables.tf       # Variables (gitops repo url, branch, path)
│       ├── outputs.tf         # Outputs (port-forward commands, password)
│       ├── values.yaml        # Argo CD server configuration
│       └── charts/
│           └── argo-apps/     # Helm chart for Applications
│               ├── Chart.yaml
│               ├── values.yaml
│               └── templates/
│                   ├── repository.yaml    # Repository Secret
│                   └── application.yaml   # Application CR
│
└── charts/
    └── django-app/            # Helm chart (for reference)
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

## GitOps Repository Structure

**Repository URL:** https://github.com/andriignedash/devops-gitops

```
devops-gitops/
├── README.md
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml         # Jenkins updates image.tag here!
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            └── hpa.yaml
```

**Current values.yaml:**

```yaml
replicaCount: 2

image:
  repository: XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-ecr
  tag: "initial"              # <-- Jenkins updates this value automatically
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 8000

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70
```

**Note:** After `terraform apply`, update `image.repository` in GitOps repo with actual ECR URL from `terraform output ecr_repository_url`.

## Cleanup

**IMPORTANT:** Delete resources in correct order!

### 1. Delete Helm releases

```bash
helm uninstall -n argocd argo-apps
helm uninstall -n argocd argocd
helm uninstall -n jenkins jenkins
```

### 2. Delete namespace resources

```bash
kubectl delete namespace django --grace-period=0 --force
kubectl delete namespace jenkins --grace-period=0 --force
kubectl delete namespace argocd --grace-period=0 --force
```

### 3. Delete Terraform resources

```bash
cd lesson-8-9

terraform destroy -auto-approve
```

**Execution time:** ~10-15 minutes

### 4. Clean ECR images (optional)

```bash
aws ecr delete-repository --repository-name lesson-8-9-ecr --region us-west-2 --force
```

## Runtime Verification

After deployment, use these commands to verify the CI/CD pipeline is working correctly.

### Check ECR Images

```bash
# List images in ECR repository
aws ecr list-images --repository-name lesson-8-9-ecr --region us-west-2

# Get detailed image info
aws ecr describe-images --repository-name lesson-8-9-ecr --region us-west-2 --output table
```

### Check Argo CD Status

```bash
# List applications
kubectl get applications -n argocd

# Check application sync status
kubectl get application django-app -n argocd -o jsonpath='{.status.sync.status}'

# Check application health
kubectl get application django-app -n argocd -o jsonpath='{.status.health.status}'
```

### Check Django Application

```bash
# List all resources in django namespace
kubectl get all -n django

# Check deployment image
kubectl describe deployment -n django django-app | grep -i image

# Check pod status
kubectl get pods -n django -o wide

# Check HPA status
kubectl get hpa -n django
```

### Expected Results After Successful Pipeline

| Check | Expected Result |
|-------|-----------------|
| Jenkins build | Green (SUCCESS) |
| ECR images | New image with git SHA tag |
| GitOps repo | New commit with updated image.tag |
| Argo CD sync | Synced |
| Argo CD health | Healthy |
| Django pods | Running (2/2 replicas) |

### Verify End-to-End Flow

```bash
# 1. Check latest commit in GitOps repo
cd /tmp && git clone https://github.com/andriignedash/devops-gitops.git --depth 1
cat devops-gitops/charts/django-app/values.yaml | grep -A 2 "image:"

# 2. Compare with running deployment
kubectl get deployment -n django django-app -o jsonpath='{.spec.template.spec.containers[0].image}'
```

If both show the same image tag, the pipeline completed successfully.

## TODO Checklist

### Completed:

- [x] **GitOps repository created:** https://github.com/andriignedash/devops-gitops
  - [x] Structure: `charts/django-app/`
  - [x] `values.yaml` with `image.repository` and `image.tag`
  - [x] Helm templates (deployment, service, hpa)

- [x] **`main.tf` updated:**
  - [x] `gitops_repo_url` set to `https://github.com/andriignedash/devops-gitops.git`
  - [x] `gitops_branch` set to `main`
  - [x] `app_chart_path` set to `charts/django-app`

- [x] **`Jenkinsfile` updated:**
  - [x] `GITOPS_REPO_URL` set to `https://github.com/andriignedash/devops-gitops.git`

### Required actions before deployment:

- [ ] **Update ECR settings after terraform apply:**
  - [ ] Get ECR URL: `terraform output ecr_repository_url`
  - [ ] Update `Jenkinsfile`: Replace `XXXXXXXXXXXX` in `ECR_REGISTRY` with your AWS Account ID
  - [ ] Update GitOps repo `values.yaml`: Replace `XXXXXXXXXXXX` in `image.repository`

- [ ] **Create GitHub Personal Access Token:**
  - [ ] https://github.com/settings/tokens
  - [ ] Scope: `repo` (full control of private repositories)
  - [ ] Add as credential in Jenkins with ID: `github_pat`

- [ ] **Configure AWS credentials:**
  - [ ] `aws configure` with permissions for EKS, ECR, VPC, S3, DynamoDB

### Optional improvements:

- [ ] **IRSA for Jenkins:** ServiceAccount annotation with IAM role ARN
- [ ] **Secrets for GitOps repo:** If private, add SSH key or token to Argo CD
- [ ] **Ingress for Jenkins/Argo CD:** Instead of port-forward
- [ ] **Prometheus + Grafana:** For monitoring
- [ ] **External Secrets Operator:** For managing secrets from AWS Secrets Manager
- [ ] **GitHub Webhooks:** Automatic trigger Jenkins pipeline on push

## Useful Links

- **Jenkins Helm Chart:** https://github.com/jenkinsci/helm-charts
- **Argo CD Docs:** https://argo-cd.readthedocs.io/
- **Kaniko:** https://github.com/GoogleContainerTools/kaniko
- **Terraform EKS:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
- **AWS ECR:** https://docs.aws.amazon.com/ecr/

## Contact and Support

**Author:** Andrii Gnedash  
**Project:** GoIT DevOps Lesson 8-9  
**Date:** 2026-01-29
