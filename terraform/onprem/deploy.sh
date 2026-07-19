#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

apply_layer() {
  local layer="$1"

  echo
  echo "================================="
  echo " Applying ${layer}"
  echo "================================="

  (
    cd "${ROOT_DIR}/${layer}"
    terraform init -input=false
    terraform plan -input=false -out=tfplan
    terraform apply -input=false tfplan
  )
}

echo "================================="
echo " On-prem Terraform deployment start"
echo "================================="

apply_layer "01-onprem-platform"
apply_layer "02-onprem-workloads"

echo
echo "================================="
echo " On-prem Terraform deployment complete"
echo "================================="
