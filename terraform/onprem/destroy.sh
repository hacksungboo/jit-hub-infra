#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

destroy_layer() {
  local layer="$1"

  echo
  echo "================================="
  echo " Destroying ${layer}"
  echo "================================="

  (
    cd "${ROOT_DIR}/${layer}"
    terraform init -input=false
    terraform destroy -input=false -auto-approve
  )
}

echo "================================="
echo " On-prem Terraform destroy start"
echo "================================="

destroy_layer "02-onprem-workloads"
destroy_layer "01-onprem-platform"

echo
echo "================================="
echo " On-prem Terraform destroy complete"
echo "================================="
