# Quick Start

## 1. Deploy

```bash
# Bootstrap (first time only)
cd lesson-8-9/bootstrap-backend
terraform init && terraform apply -auto-approve

# Main infrastructure
cd ..
terraform init -reconfigure && terraform apply -auto-approve
```

## 2. Configure kubectl

```bash
aws eks update-kubeconfig --name lesson-8-9-eks --region us-west-2
```

## 3. Jenkins

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
```

Open http://localhost:8080 | User: admin

Add credential:
- Kind: Secret text
- Secret: GitHub PAT
- ID: `github_pat`

Create pipeline → Git → `https://github.com/andriignedash/devops` → Branch: `*/lesson-8-9` → Script: `Jenkinsfile`

## 4. Argo CD

```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Open http://localhost:8081 | User: admin

## 5. Verify

```bash
kubectl get pods -n jenkins
kubectl get pods -n argocd
kubectl get applications -n argocd
```

## 6. Cleanup

```bash
terraform destroy -auto-approve
```
