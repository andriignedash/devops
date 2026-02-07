#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
. "$SCRIPT_DIR/env.sh"
cd "$ROOT_DIR"
terraform init -reconfigure
if [ -n "${TF_VAR_db_password:-}" ]; then
  terraform apply -var-file=terraform.tfvars.safe
else
  terraform apply -var-file=terraform.tfvars.safe -var='db_password=TempStrongPass123!'
fi
