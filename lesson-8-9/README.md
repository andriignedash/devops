# Lesson 8–9: CI/CD with Jenkins, Argo CD and EKS (GitOps)

This project implements a full CI/CD pipeline using Jenkins, Terraform, Helm, Amazon ECR and Argo CD.

Flow:
Git push → Jenkins (Kaniko) builds Docker image → pushes to ECR → updates Helm values in GitOps repo → Argo CD automatically syncs to EKS.

---

## Repositories

| Repo | URL | Purpose |
|------|-----|---------|
| Infrastructure | https://github.com/andriignedash/devops | Terraform, Jenkinsfile |
| GitOps | https://github.com/andriignedash/devops-gitops | Helm charts and image tags |

---

## Prerequisites

- AWS CLI configured
- Terraform >= 1.5
- kubectl
- helm
- GitHub Personal Access Token with `repo` scope
- AWS region: `us-west-2`

---

## 1. How to apply Terraform

### 1.1 Bootstrap Terraform backend (S3 + DynamoDB)

```bash
cd lesson-8-9/bootstrap-backend
terraform init
terraform apply -auto-approve
```

### 1.2 Deploy infrastructure

```bash
cd lesson-8-9
terraform init -reconfigure
terraform apply -auto-approve
```

### 1.3 Configure kubectl for EKS

```bash
aws eks update-kubeconfig --name lesson-8-9-eks --region us-west-2
kubectl get nodes
```

### 1.4 Verify infrastructure

```bash
kubectl get ns | egrep 'jenkins|argocd'
kubectl -n jenkins get pods,svc
kubectl -n argocd get pods,svc
helm -n jenkins list
helm -n argocd list
```

---

## 2. How to verify Jenkins job

### 2.1 Access Jenkins

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d; echo
```

URL: http://localhost:8080

Login: admin

### 2.2 Configure credentials

Manage Jenkins → Credentials → Add Credentials

- Kind: Secret text
- Secret: GitHub PAT
- ID: `github_pat`

### 2.3 Create Jenkins pipeline

New Item → Pipeline

- SCM: Git
- Repository: https://github.com/andriignedash/devops
- Branch: `*/lesson-8-9`
- Script path: `Jenkinsfile`

Run **Build Now**.

### 2.4 Verify pipeline results

Check that the image was pushed to ECR:

```bash
aws ecr describe-images \
  --repository-name lesson-8-9-ecr \
  --region us-west-2
```

Check that GitOps repo was updated:

```bash
git clone https://github.com/andriignedash/devops-gitops.git
cd devops-gitops
git log -n 3 --oneline
grep -n "tag:" charts/django-app/values.yaml
```

---

## 3. How to see the result in Argo CD

### 3.1 Access Argo CD

```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

URL: http://localhost:8081

Login: admin

### 3.2 Verify application sync

In Argo CD UI:

- Application: `django-app`
- Sync status: Synced
- Auto-Sync: enabled
- Revision matches latest GitOps commit

CLI check:

```bash
kubectl -n argocd get applications
kubectl -n django get pods
kubectl -n django get deploy django-app \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

The image tag must match the tag pushed by Jenkins.

---

## Cleanup

```bash
cd lesson-8-9
terraform destroy -auto-approve
```

---

## Project Structure

```
lesson-8-9/
├── main.tf
├── backend.tf
├── outputs.tf
├── bootstrap-backend/
└── modules/
    ├── vpc/
    ├── eks/
    ├── ecr/
    ├── jenkins/
    └── argo_cd/
```
