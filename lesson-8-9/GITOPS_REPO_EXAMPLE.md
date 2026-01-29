# GitOps Repository - Example Structure

## Repository Structure

Create a separate repository (e.g., `django-gitops-repo`) with the following structure:

```
django-gitops-repo/
├── README.md
└── charts/
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml          # Jenkins updates image.tag here
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── hpa.yaml
            └── configmap.yaml
```

## Files

### Chart.yaml

```yaml
apiVersion: v2
name: django-app
description: Django Application Helm Chart
type: application
version: 1.0.0
appVersion: "1.0"
```

### values.yaml

```yaml
replicaCount: 2

image:
  repository: XXXXXXXXXXXX.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-ecr
  tag: "latest"
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
  - name: ALLOWED_HOSTS
    value: "*"
```

**IMPORTANT:** 
- Replace `XXXXXXXXXXXX` with your AWS Account ID
- Jenkins will update `image.tag` on each build

### templates/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        env:
        {{- range .Values.env }}
        - name: {{ .name }}
          value: {{ .value | quote }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: {{ .Values.service.targetPort }}
          initialDelaySeconds: 10
          periodSeconds: 5
```

### templates/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    protocol: TCP
  selector:
    app: {{ .Chart.Name }}
```

### templates/hpa.yaml

```yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Chart.Name }}
  labels:
    app: {{ .Chart.Name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Chart.Name }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
{{- end }}
```

### templates/configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-config
  labels:
    app: {{ .Chart.Name }}
data:
  DJANGO_SETTINGS_MODULE: "config.settings"
  DEBUG: "False"
```

## Creating Repository

### 1. Create Repository on GitHub

```bash
gh repo create django-gitops-repo --public --clone
cd django-gitops-repo
```

### 2. Create Structure

```bash
mkdir -p charts/django-app/templates

touch charts/django-app/Chart.yaml
touch charts/django-app/values.yaml
touch charts/django-app/templates/deployment.yaml
touch charts/django-app/templates/service.yaml
touch charts/django-app/templates/hpa.yaml
touch charts/django-app/templates/configmap.yaml
```

### 3. Copy Content

Copy file contents from examples above or from `lesson-8-9/charts/django-app/`

### 4. Commit and Push

```bash
git add .
git commit -m "Initial GitOps repository structure"
git push origin main
```

### 5. Update Configuration

Update repository URL in:
- `lesson-8-9/main.tf` (module "argo_cd")
- `Jenkinsfile` (env.GITOPS_REPO_URL)

## Verification

After Jenkins setup and first pipeline run:

```bash
cd django-gitops-repo
git pull

git log -1
```

You should see a commit from Jenkins with updated `image.tag` in `values.yaml`
