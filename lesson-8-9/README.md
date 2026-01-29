# Lesson 8-9: CI/CD с Jenkins, Argo CD, Helm, Terraform, ECR и EKS

## Архитектура CI/CD

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                           │
│                                                                       │
│  1. Git Push → GitHub                                                │
│  2. Jenkins Pipeline (EKS Pod с Kaniko)                             │
│     ├─ Checkout Code                                                 │
│     ├─ Build Docker Image (Kaniko - без Docker daemon)              │
│     ├─ Push to ECR (image:tag + image:latest)                       │
│     └─ Update GitOps Repo (values.yaml с новым tag)                 │
│                                                                       │
│  3. Argo CD (GitOps Controller)                                      │
│     ├─ Detect изменения в GitOps репозитории                        │
│     ├─ Auto Sync (selfHeal + prune)                                 │
│     └─ Deploy в EKS namespace 'django'                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      Infrastructure (Terraform)                      │
│                                                                       │
│  AWS Infrastructure:                                                 │
│  ├─ VPC (3 AZ, public/private subnets)                             │
│  ├─ EKS Cluster v1.29 (2-6 nodes t3.medium)                        │
│  ├─ ECR Repository (для Docker образов)                            │
│  └─ S3 + DynamoDB (Terraform state backend)                        │
│                                                                       │
│  Kubernetes Apps (Helm via Terraform):                              │
│  ├─ Jenkins (namespace: jenkins)                                    │
│  │  ├─ Controller с JCasC                                          │
│  │  ├─ Kubernetes Cloud Agent (Kaniko pod template)                │
│  │  └─ PVC 10Gi (gp2)                                              │
│  │                                                                   │
│  └─ Argo CD (namespace: argocd)                                     │
│     ├─ Server (insecure mode для простоты)                         │
│     ├─ Application Controller                                       │
│     ├─ Repository Secret (GitOps repo)                             │
│     └─ Application CR (django-app)                                  │
└─────────────────────────────────────────────────────────────────────┘
```

## Требования

### Установленные инструменты

- **AWS CLI** (настроен с credentials)
- **Terraform** >= 1.5.0
- **kubectl**
- **Docker** (для локальных тестов, опционально)
- **git**
- **jq** (опционально, для парсинга JSON)

### AWS Resources

- Аккаунт AWS с правами на создание:
  - VPC, Subnets, Internet Gateway, NAT Gateway
  - EKS Cluster, Node Groups
  - ECR Repository
  - S3 Bucket, DynamoDB Table
  - IAM Roles и Policies

## Быстрый старт

### 1. Подготовка репозиториев

#### А) Основной репозиторий (текущий)

Этот репозиторий содержит:
- Terraform инфраструктуру (`lesson-8-9/`)
- Исходный код Django приложения (`docker-django-nginx/app/`)
- **Jenkinsfile** (в корне репозитория)

#### Б) GitOps репозиторий (TODO: создать отдельно)

Создайте отдельный GitOps репозиторий со структурой:

```
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml          # <-- Jenkins будет обновлять image.tag здесь
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

**TODO:** Обновите `main.tf` с URL вашего GitOps репозитория:

```hcl
module "argo_cd" {
  # ...
  gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
}
```

### 2. Deploy инфраструктуры

```bash
cd lesson-8-9

terraform init

terraform plan

terraform apply -auto-approve
```

**Время выполнения:** ~15-20 минут

**Создаст:**
- VPC с 3 availability zones
- EKS cluster с 2 worker nodes
- ECR repository
- Jenkins (namespace: jenkins)
- Argo CD (namespace: argocd)

### 3. Настройка kubectl

```bash
aws eks update-kubeconfig --name lesson-8-9-eks --region us-west-2

kubectl get nodes

kubectl get pods -A
```

### 4. Проверка outputs

```bash
terraform output

terraform output -raw ecr_repository_url

terraform output -raw jenkins_port_forward

terraform output -raw argocd_port_forward
```

## Jenkins: Настройка и использование

### 1. Открыть Jenkins UI

```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

Откройте в браузере: http://localhost:8080

### 2. Получить admin пароль

```bash
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d

echo
```

**Логин:** `admin`  
**Пароль:** (из команды выше)

### 3. Настройка Credentials

#### GitHub Personal Access Token

1. В Jenkins UI: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials**:
   - **Kind:** Secret text
   - **Secret:** (ваш GitHub PAT с правами `repo`)
   - **ID:** `github_pat`
   - **Description:** GitHub Personal Access Token

**TODO:** Создайте GitHub PAT:
- https://github.com/settings/tokens
- Права: `repo` (full control of private repositories)

#### AWS ECR Credentials (опционально)

Kaniko использует Amazon ECR Credential Helper автоматически через IAM роль ноды.

**TODO (если нужен IRSA):** Настройте IRSA для pod'а Jenkins:
- Создайте IAM роль с политикой `AmazonEC2ContainerRegistryPowerUser`
- Добавьте аннотацию `eks.amazonaws.com/role-arn` в ServiceAccount

### 4. Создание Pipeline Job

1. **New Item** → **Pipeline** → имя: `django-app-pipeline`
2. **Pipeline**:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** (URL этого репозитория)
   - **Branch:** `*/lesson-8-9`
   - **Script Path:** `Jenkinsfile`
3. **Save**

### 5. Настройка переменных окружения (опционально)

В **Configure** → **Pipeline** → **Environment Variables** (через EnvInject или в самом Jenkinsfile):

```groovy
ECR_REGISTRY=XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com
ECR_REPOSITORY=lesson-8-9-ecr
AWS_REGION=us-west-2
GITOPS_REPO_URL=https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git
GITOPS_BRANCH=main
GITOPS_VALUES_PATH=charts/django-app/values.yaml
```

**TODO:** Обновите переменные в Jenkinsfile или через Jenkins UI.

### 6. Запуск Pipeline

**Build Now** → Проверьте логи в **Console Output**

**Этапы:**
1. **Checkout** - клонирование репозитория
2. **Build & Push to ECR** - Kaniko build + push
3. **Update GitOps Repo** - обновление `values.yaml` с новым tag

## Argo CD: Настройка и мониторинг

### 1. Открыть Argo CD UI

```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
```

Откройте в браузере: http://localhost:8081

### 2. Получить admin пароль

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

echo
```

**Логин:** `admin`  
**Пароль:** (из команды выше)

### 3. Проверка Application

В Argo CD UI:
- **Applications** → `django-app`
- **Status:** Healthy (после первого sync)
- **Sync Status:** Synced

**Автоматический sync:**
- `prune: true` - удаляет старые ресурсы
- `selfHeal: true` - восстанавливает при manual changes
- `CreateNamespace: true` - создает namespace автоматически

### 4. Manual Sync (если нужно)

```bash
kubectl get applications -n argocd

kubectl get application django-app -n argocd -o yaml

argocd app sync django-app
```

Или через UI: **Sync** → **Synchronize**

### 5. Мониторинг обновлений

После того, как Jenkins обновит GitOps репозиторий:

1. Argo CD обнаружит изменения (~30 секунд)
2. Auto-sync запустится
3. Новый образ будет задеплоен в namespace `django`

**Проверка:**

```bash
kubectl get pods -n django

kubectl describe deployment -n django django-app

kubectl rollout status deployment/django-app -n django
```

## GitOps Workflow: Полный цикл

### 1. Локальная разработка

```bash
cd docker-django-nginx/app

git checkout -b feature/new-feature

# Вносите изменения в код...
```

### 2. Commit и Push

```bash
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
```

### 3. Запуск Jenkins Pipeline

**В Jenkins:**
- Настройте webhook или запустите pipeline вручную
- Pipeline выполнит:
  - Build образа с тегом `git-sha-short`
  - Push в ECR: `image:abc1234` + `image:latest`
  - Update GitOps repo: `image.tag: "abc1234"`

**TODO:** Настройте GitHub webhook:
- Payload URL: `http://jenkins-external-url/github-webhook/`
- Content type: `application/json`
- Events: Just the push event

### 4. Argo CD Auto-Sync

Argo CD автоматически:
1. Обнаружит изменения в `values.yaml`
2. Запустит sync
3. Обновит deployment с новым образом
4. Kubernetes выполнит rolling update

### 5. Проверка деплоя

```bash
kubectl get pods -n django -w

kubectl logs -n django deployment/django-app -f

kubectl get events -n django --sort-by='.lastTimestamp'
```

### 6. Доступ к приложению

```bash
kubectl get svc -n django

export DJANGO_URL=$(kubectl get svc -n django django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$DJANGO_URL
```

## Команды для проверки

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

### Jenkins не запускается

```bash
kubectl get events -n jenkins --sort-by='.lastTimestamp'

kubectl describe pod -n jenkins <jenkins-pod-name>

kubectl logs -n jenkins <jenkins-pod-name> --previous
```

**Частые проблемы:**
- PVC не создан (проверьте storage class)
- Недостаточно ресурсов на нодах

### Kaniko build fails

**Ошибка:** `error building image: getting stage builder`

**Решение:**
- Проверьте, что Dockerfile существует по пути
- Проверьте, что context path правильный
- Проверьте ресурсы pod'а (memory, cpu)

**Ошибка:** `error pushing image: denied`

**Решение:**
- Проверьте IAM роль ноды (должна иметь права на ECR)
- Проверьте ECR repository URL

### Argo CD не синхронизирует

```bash
kubectl logs -n argocd deployment/argocd-application-controller

kubectl get application django-app -n argocd -o yaml | grep -A 10 status
```

**Частые проблемы:**
- GitOps репозиторий недоступен (проверьте Repository Secret)
- Неправильный path к chart
- RBAC проблемы

### Django app не доступен

```bash
kubectl get svc -n django django-app -o wide

kubectl describe svc -n django django-app

kubectl get endpoints -n django
```

**LoadBalancer не получает external IP:**
- Проверьте AWS Load Balancer Controller
- Проверьте subnet tags для ELB
- Проверьте security groups

## Структура проекта

```
lesson-8-9/
├── backend.tf              # S3 backend configuration
├── main.tf                 # Основные модули (VPC, EKS, ECR, Jenkins, Argo CD)
├── outputs.tf              # Terraform outputs
├── README.md               # Этот файл
│
├── modules/
│   ├── s3-backend/         # S3 + DynamoDB для state
│   ├── vpc/                # VPC с public/private subnets
│   ├── ecr/                # ECR repository
│   ├── eks/                # EKS cluster + node group
│   │
│   ├── jenkins/            # Jenkins Helm release
│   │   ├── jenkins.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── values.yaml.tpl  # Jenkins values с Kaniko agent
│   │
│   └── argo_cd/            # Argo CD + Applications
│       ├── argo_cd.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── values.yaml      # Argo CD server config
│       └── charts/
│           └── argo-apps/   # Helm chart для Applications
│               ├── Chart.yaml
│               ├── values.yaml
│               └── templates/
│                   ├── repository.yaml    # Repository Secret
│                   └── application.yaml   # Application CR
│
└── charts/
    └── django-app/         # Helm chart (для reference, не используется в GitOps)
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

## GitOps Repository Structure (TODO)

Создайте отдельный репозиторий:

```
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml         # Jenkins обновляет image.tag здесь!
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

**values.yaml пример:**

```yaml
replicaCount: 2

image:
  repository: XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-ecr
  tag: "abc1234"              # <-- Jenkins обновляет это значение
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

env:
  - name: DJANGO_SETTINGS_MODULE
    value: config.settings
  - name: DEBUG
    value: "False"
```

## Cleanup

**ВАЖНО:** Удаление ресурсов в правильном порядке!

### 1. Удалить Helm releases

```bash
helm uninstall -n argocd argo-apps
helm uninstall -n argocd argocd
helm uninstall -n jenkins jenkins
```

### 2. Удалить namespace resources

```bash
kubectl delete namespace django --grace-period=0 --force
kubectl delete namespace jenkins --grace-period=0 --force
kubectl delete namespace argocd --grace-period=0 --force
```

### 3. Удалить Terraform resources

```bash
cd lesson-8-9

terraform destroy -auto-approve
```

**Время выполнения:** ~10-15 минут

### 4. Очистка ECR images (опционально)

```bash
aws ecr delete-repository --repository-name lesson-8-9-ecr --region us-west-2 --force
```

## TODO Checklist

### Обязательные действия перед запуском:

- [ ] **Создать GitOps репозиторий** (отдельный от этого)
  - [ ] Структура: `charts/django-app/`
  - [ ] Добавить `values.yaml` с `image.repository` и `image.tag`
  - [ ] Добавить Helm templates (можно скопировать из `lesson-8-9/charts/django-app/`)

- [ ] **Обновить `main.tf`:**
  - [ ] Заменить `gitops_repo_url` на URL вашего GitOps репозитория
  - [ ] Заменить `bucket_name` на уникальное имя (если нужно)

- [ ] **Обновить `backend.tf`:**
  - [ ] Заменить `bucket_name` на существующий или создать новый

- [ ] **Обновить `Jenkinsfile`:**
  - [ ] Заменить `ECR_REGISTRY` на ваш AWS Account ID
  - [ ] Заменить `GITOPS_REPO_URL` на URL GitOps репозитория

- [ ] **Создать GitHub Personal Access Token:**
  - [ ] https://github.com/settings/tokens
  - [ ] Права: `repo`
  - [ ] Добавить как credential в Jenkins с ID: `github_pat`

- [ ] **Настроить AWS credentials:**
  - [ ] `aws configure` с правами на создание EKS, ECR, VPC, S3, DynamoDB

### Опциональные улучшения:

- [ ] **IRSA для Jenkins:** ServiceAccount аннотация с IAM role ARN
- [ ] **Secrets для GitOps repo:** Если приватный, добавить SSH key или token в Argo CD
- [ ] **Ingress для Jenkins/Argo CD:** Вместо port-forward
- [ ] **Prometheus + Grafana:** Для мониторинга
- [ ] **External Secrets Operator:** Для управления secrets из AWS Secrets Manager
- [ ] **GitHub Webhooks:** Автоматический trigger Jenkins pipeline при push

## Полезные ссылки

- **Jenkins Helm Chart:** https://github.com/jenkinsci/helm-charts
- **Argo CD Docs:** https://argo-cd.readthedocs.io/
- **Kaniko:** https://github.com/GoogleContainerTools/kaniko
- **Terraform EKS:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
- **AWS ECR:** https://docs.aws.amazon.com/ecr/

## Контакты и поддержка

**Автор:** Andrii Gnedash  
**Проект:** GoIT DevOps Lesson 8-9  
**Дата:** 2026-01-29
