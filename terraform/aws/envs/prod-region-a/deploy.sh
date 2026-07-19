#!/bin/bash

set -e

ROOT_DIR=$(pwd)

echo "================================="
echo " Terraform Deployment Start"
echo "================================="

apply_layer () {
  LAYER=$1

  echo ""
  echo "================================="
  echo " Applying ${LAYER}"
  echo "================================="

  cd "${ROOT_DIR}/${LAYER}"

  terraform init

  terraform plan -out=tfplan

  terraform apply tfplan
}


apply_layer "01-network"

apply_layer "02-eks"

apply_layer "03-platform"

apply_layer "04-eks-workloads"

apply_layer "05-eks-autoscaling"

echo ""
echo "================================="
echo " Terraform Deployment Complete"
echo "================================="