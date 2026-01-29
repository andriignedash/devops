# Quick Start: Lesson 8-9

## Repository Structure

This project uses **two repositories**:

| Repository | URL | Branch |
|------------|-----|--------|
| **Infrastructure** | https://github.com/andriignedash/devops | `lesson-8-9` |
| **GitOps** | https://github.com/andriignedash/devops-gitops | `main` |

## ⚠️ BEFORE STARTING

### 1. Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Generate new token with `repo` scope (full control)
3. Save token (will be needed for Jenkins credential)

### 2. Update ECR Registry (after terraform apply)

After deploying infrastructure, update the AWS Account ID:

**Jenkinsfile (line 7):**
```groovy
ECR_REGISTRY = "XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com"
```

**GitOps repo values.yaml:**
```yaml
image:
  repository: XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-ecr
```

Replace `XXXXXXXXXXXX` with your actual AWS Account ID.

## 🚀 Deploy Infrastructure

```bash
cd lesson-8-9

terraform init
terraform apply -auto-approve
```

⏱️ Time: ~15-20 minutes

### Get ECR URL:
```bash
terraform output ecr_repository_url
```

## 🔧 Jenkins Setup

### Open UI:
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

URL: http://localhost:8080

### Get Password:
```bash
kubectl get secret -n jenkins jenkins \
  -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
echo
```

### Add GitHub PAT Credential:
1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - Kind: `Secret text`
   - Secret: (your GitHub PAT)
   - ID: `github_pat`
   - Description: GitHub Personal Access Token

### Create Pipeline Job:
1. **New Item** → **Pipeline** → Name: `django-app-pipeline`
2. **Pipeline**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/andriignedash/devops`
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`
3. **Save**

## 📊 Argo CD Setup

### Open UI:
```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
```

URL: http://localhost:8081

### Get Password:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
```

Login: `admin`

### Verify Application:
- Go to **Applications** → `django-app`
- Status should show: Synced / Healthy (after first successful Jenkins build)

## ✅ Verification Commands

```bash
# Check EKS nodes
kubectl get nodes

# Check Jenkins
kubectl get pods -n jenkins

# Check Argo CD
kubectl get pods -n argocd
kubectl get applications -n argocd

# Check Django app (after first deploy)
kubectl get all -n django
```

## 🔄 Full CI/CD Cycle

```
1. Developer pushes code to devops repo (lesson-8-9)
         ↓
2. Jenkins Pipeline runs:
   - Checkout code
   - Build Docker image with Kaniko
   - Push to ECR (tag + latest)
   - Clone devops-gitops repo
   - Update image.tag in values.yaml
   - Commit and push to main
         ↓
3. Argo CD detects change (~30 seconds)
         ↓
4. Auto-sync deploys to EKS namespace 'django'
         ↓
5. Application updated with zero downtime
```

### Test the Pipeline:
1. Run **Build Now** in Jenkins
2. Watch Argo CD UI for sync
3. Check pods: `kubectl get pods -n django -w`

## 🧹 Cleanup

```bash
# Delete Helm releases
helm uninstall -n argocd argo-apps
helm uninstall -n argocd argocd
helm uninstall -n jenkins jenkins

# Delete namespaces
kubectl delete namespace django jenkins argocd

# Destroy infrastructure
cd lesson-8-9
terraform destroy -auto-approve
```

## 📚 Detailed Documentation

See [README.md](README.md) for complete documentation.
