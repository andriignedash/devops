# Lesson 8-9: CI/CD with Jenkins, Argo CD & EKS

## Architecture

```
Developer → Git Push → Jenkins (Kaniko) → ECR → GitOps Repo → Argo CD → EKS
```

**Two repositories:**
| Repo | URL | Purpose |
|------|-----|---------|
| Infrastructure | github.com/andriignedash/devops | Terraform, Jenkinsfile |
| GitOps | github.com/andriignedash/devops-gitops | Helm charts |

## Requirements

- AWS CLI (configured)
- Terraform >= 1.5.0
- kubectl

## Quick Deploy

### 1. Bootstrap Backend

```bash
cd lesson-8-9/bootstrap-backend
terraform init && terraform apply -auto-approve
```

### 2. Deploy Infrastructure

```bash
cd lesson-8-9
terraform init -reconfigure
terraform apply -auto-approve
```

Time: ~15-20 min

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --name lesson-8-9-eks --region us-west-2
```

## Access Services

### Jenkins

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
```

URL: http://localhost:8080 | Login: admin

### Argo CD

```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

URL: http://localhost:8081 | Login: admin

## Setup Jenkins

1. Add credential: **Manage Jenkins** → **Credentials** → **Add**
   - Kind: `Secret text`
   - Secret: GitHub PAT (repo scope)
   - ID: `github_pat`

2. Create pipeline: **New Item** → **Pipeline**
   - SCM: Git
   - URL: `https://github.com/andriignedash/devops`
   - Branch: `*/lesson-8-9`
   - Script: `Jenkinsfile`

3. Update `Jenkinsfile` ECR_REGISTRY with your AWS Account ID

## Verify

```bash
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl get pods -n django
```

## Cleanup

```bash
cd lesson-8-9
terraform destroy -auto-approve
```

## Project Structure

```
lesson-8-9/
├── main.tf, backend.tf, outputs.tf
├── bootstrap-backend/
└── modules/
    ├── vpc/, eks/, ecr/
    ├── jenkins/
    └── argo_cd/
```
