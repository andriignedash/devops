# Django app

Minimal Django app for final project.

## Jenkins (required env/credentials)

- `aws-region`: AWS region (e.g. eu-central-1)
- `ecr-registry-url`: ECR registry URL (e.g. 123456789.dkr.ecr.eu-central-1.amazonaws.com)
- `ecr-repository-name`: ECR repository name (e.g. django-app)

Create these as Secret text credentials in Jenkins and use the same IDs in the Jenkinsfile.

## Local run

```bash
docker-compose up --build
```

Open http://localhost:8000/health/
