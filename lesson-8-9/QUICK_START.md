# Quick Start: Lesson 8-9

## ⚠️ BEFORE STARTING - IMPORTANT!

### 1. Create GitOps Repository

Create a separate repository with structure:

```
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml    # Important: image.repository and image.tag
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

You can copy from `lesson-8-9/charts/django-app/`

### 2. Update Configuration

**main.tf (line ~98):**
```hcl
gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
```

**Jenkinsfile (lines 7-9):**
```groovy
ECR_REGISTRY = "XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com"
ECR_REPOSITORY = "lesson-8-9-ecr"
GITOPS_REPO_URL = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
```

### 3. Create GitHub Personal Access Token

1. https://github.com/settings/tokens
2. Scope: `repo` (full control)
3. Save token (will be needed for Jenkins)

## 🚀 Launch

```bash
cd lesson-8-9

terraform init
terraform apply -auto-approve
```

⏱️ Time: ~15-20 minutes

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

### Add GitHub PAT:
1. **Manage Jenkins** → **Credentials**
2. **Add Credentials**:
   - Kind: `Secret text`
   - Secret: (your GitHub PAT)
   - ID: `github_pat`

### Create Pipeline:
1. **New Item** → **Pipeline**
2. **Pipeline script from SCM**
   - SCM: Git
   - Repository URL: (this repository)
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`

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

## ✅ Verification

```bash
kubectl get nodes

kubectl get pods -n jenkins

kubectl get pods -n argocd

kubectl get applications -n argocd

kubectl get all -n django
```

## 🔄 Full CI/CD Cycle

1. **Push code** → GitHub
2. **Run Jenkins Pipeline** (Build Now)
3. **Jenkins**:
   - Build image with Kaniko
   - Push to ECR
   - Update GitOps repo
4. **Argo CD**:
   - Automatically detects changes
   - Syncs with cluster
5. **Check deployment**:
   ```bash
   kubectl get pods -n django -w
   ```

## 🧹 Cleanup

```bash
helm uninstall -n argocd argo-apps
helm uninstall -n argocd argocd
helm uninstall -n jenkins jenkins

kubectl delete namespace django jenkins argocd

terraform destroy -auto-approve
```

## 📚 Detailed Documentation

See [README.md](README.md)
