# Quick Start

## AWS Profile Setup

Source the helper script or set environment manually:

```bash
. scripts/env.sh
```

Or manually:

```bash
export AWS_PROFILE=final
export AWS_REGION=eu-central-1
export AWS_DEFAULT_REGION=eu-central-1
aws sts get-caller-identity --region eu-central-1
```

## Apply (zsh-safe)

Use single quotes around `-var` so `!` is not expanded by zsh history:

```bash
terraform apply -var-file=terraform.tfvars.example -var='db_password=TempStrongPass123!'
```

Or use the wrapper script:

```bash
export TF_VAR_db_password='YourPassword!'
./scripts/apply.sh
```

Alternative: `set +H` disables zsh history expansion entirely.

## After a Successful Apply

```bash
aws eks update-kubeconfig --profile final --region eu-central-1 --name final-eks
kubectl get nodes
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

If you get `Unauthorized`, ensure `AWS_PROFILE=final` is set and kubeconfig is updated:

```bash
. scripts/env.sh
aws eks update-kubeconfig --profile final --region eu-central-1 --name final-eks
```

---

## Step 1: Bootstrap Backend

```bash
cd bootstrap-backend
terraform init
terraform apply -var="bucket_name=YOUR_UNIQUE_TFSTATE_BUCKET" -var="dynamodb_table_name=YOUR_TFSTATE_LOCKS" -var="region=eu-central-1"
```

Note the outputs: `bucket_name`, `dynamodb_table_name`, `region`.

## Step 2: Configure Root Backend

Edit root `backend.tf`: set `bucket`, `dynamodb_table`, and `region` from Step 1.

Then:

```bash
cd ..
terraform init -reconfigure
```

## Step 3: Apply

```bash
cp terraform.tfvars.example terraform.tfvars
# Set db_password if create_db = true
terraform plan
terraform apply
```

## Step 4: Configure kubeconfig

```bash
aws eks update-kubeconfig --region eu-central-1 --name final-eks
```

## Step 5: Check Namespaces

```bash
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

## Step 6: Port-forward

- Jenkins: `kubectl port-forward svc/jenkins 8080:8080 -n jenkins` (http://localhost:8080)
- Argo CD: `kubectl port-forward svc/argo-cd-argocd-server 8081:443 -n argocd` (https://localhost:8081)
- Grafana: `kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring` (http://localhost:3000)

## Destroy

```bash
terraform destroy
```

If dependencies fail, destroy in order: Helm releases, EKS node group/cluster, RDS, VPC. Do not destroy `bootstrap-backend` unless you have migrated state.
