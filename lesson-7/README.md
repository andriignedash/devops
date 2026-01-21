# Lesson 7: Django on EKS with Terraform & Helm

## Overview

Django application deployment to Amazon EKS using Terraform, Docker, Helm, and Horizontal Pod Autoscaler.

## Architecture

**Infrastructure (Terraform):**
- VPC with public/private subnets across 3 AZs
- EKS Cluster v1.29 with Node Group (2-6 nodes, t3.medium)
- ECR Repository
- S3 Backend for state management

**Kubernetes (Helm):**
- Deployment with 2 initial replicas
- LoadBalancer Service (port 80 → 8000)
- HPA: 2-6 replicas at CPU > 70%
- ConfigMap for Django environment variables

## Quick Start

### Prerequisites

- AWS CLI configured
- Terraform >= 1.5.0
- Docker Desktop
- kubectl
- Helm 3+

### 1. Deploy Infrastructure

```bash
cd lesson-7
terraform init
terraform apply -auto-approve
```

**Creates:** VPC, EKS cluster, ECR repository (~15-20 min)

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --name lesson-7-eks --region us-west-2
kubectl get nodes
```

### 3. Build & Push Docker Image

```bash
cd ../docker-django-nginx/app

docker build --platform linux/amd64 -t django-app:lesson-7 .

ECR_URL=$(cd ../../lesson-7 && terraform output -raw ecr_repository_url)

aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin ${ECR_URL%/*}

docker tag django-app:lesson-7 $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 5. Deploy Application

```bash
cd ../../lesson-7/charts
helm install django-app ./django-app
```

### 6. Verify Deployment

```bash
kubectl get pods,svc,hpa

curl http://$(kubectl get svc django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Configuration

Edit `charts/django-app/values.yaml` to customize:

```yaml
replicaCount: 2

image:
  repository: <ECR_URL>
  tag: latest

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 70
```

Update deployment:
```bash
helm upgrade django-app ./django-app
```

## Project Structure

```
lesson-7/
├── backend.tf
├── main.tf
├── outputs.tf
├── modules/
│   ├── s3-backend/
│   ├── vpc/
│   ├── ecr/
│   └── eks/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

## Monitoring

```bash
kubectl top pods
kubectl top nodes
kubectl get hpa -w
```

## Troubleshooting

```bash
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl rollout restart deployment django-app
```

## Cleanup

```bash
helm uninstall django-app
terraform destroy -auto-approve
```

## Useful Commands

```bash
terraform output
helm list
kubectl get all
aws eks list-clusters
aws ecr describe-repositories
```

## Requirements Checklist

- [x] Terraform EKS module
- [x] Node group autoscaling (2-6 nodes)
- [x] Django Docker image in ECR
- [x] Helm chart (Deployment, Service, HPA, ConfigMap)
- [x] HPA: 2-6 replicas at CPU > 70%
- [x] LoadBalancer Service with public access
- [x] Complete documentation
