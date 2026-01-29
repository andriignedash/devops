# Быстрый старт: Lesson 8-9

## ⚠️ ПЕРЕД ЗАПУСКОМ - ВАЖНО!

### 1. Создайте GitOps репозиторий

Создайте отдельный репозиторий со структурой:

```
gitops-repo/
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml    # Важно: image.repository и image.tag
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

Можно скопировать из `lesson-8-9/charts/django-app/`

### 2. Обновите конфигурацию

**main.tf (строка ~98):**
```hcl
gitops_repo_url = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
```

**Jenkinsfile (строки 7-9):**
```groovy
ECR_REGISTRY = "XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com"
ECR_REPOSITORY = "lesson-8-9-ecr"
GITOPS_REPO_URL = "https://github.com/YOUR_USERNAME/YOUR_GITOPS_REPO.git"
```

### 3. Создайте GitHub Personal Access Token

1. https://github.com/settings/tokens
2. Права: `repo` (full control)
3. Сохраните токен (понадобится для Jenkins)

## 🚀 Запуск

```bash
cd lesson-8-9

terraform init
terraform apply -auto-approve
```

⏱️ Время: ~15-20 минут

## 🔧 Настройка Jenkins

### Открыть UI:
```bash
kubectl port-forward -n jenkins svc/jenkins 8080:8080
```

URL: http://localhost:8080

### Получить пароль:
```bash
kubectl get secret -n jenkins jenkins \
  -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
echo
```

### Добавить GitHub PAT:
1. **Manage Jenkins** → **Credentials**
2. **Add Credentials**:
   - Kind: `Secret text`
   - Secret: (ваш GitHub PAT)
   - ID: `github_pat`

### Создать Pipeline:
1. **New Item** → **Pipeline**
2. **Pipeline script from SCM**
   - SCM: Git
   - Repository URL: (этот репозиторий)
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`

## 📊 Настройка Argo CD

### Открыть UI:
```bash
kubectl port-forward -n argocd svc/argocd-server 8081:80
```

URL: http://localhost:8081

### Получить пароль:
```bash
kubectl get secret -n argocd argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
```

Логин: `admin`

## ✅ Проверка

```bash
kubectl get nodes

kubectl get pods -n jenkins

kubectl get pods -n argocd

kubectl get applications -n argocd

kubectl get all -n django
```

## 🔄 Полный CI/CD цикл

1. **Push код** → GitHub
2. **Запустить Jenkins Pipeline** (Build Now)
3. **Jenkins**:
   - Build образа с Kaniko
   - Push в ECR
   - Update GitOps repo
4. **Argo CD**:
   - Автоматически обнаружит изменения
   - Синхронизирует с кластером
5. **Проверить деплой**:
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

## 📚 Подробная документация

См. [README.md](README.md)
