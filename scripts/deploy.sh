#!/bin/bash
# Deployment script for EKS infrastructure

set -e

ENVIRONMENT="${1:-dev}"
COMPONENT="${2:-all}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <environment> [component]"
  echo "Components: network, eks, addons, applications, all"
  exit 1
fi

cd "$(dirname "$0")/../environments/$ENVIRONMENT"

case "$COMPONENT" in
  network)
    cd 01-network
    terraform init
    terraform plan
    terraform apply
    ;;
  eks)
    cd 02-eks
    terraform init
    terraform plan
    terraform apply
    ;;
  addons)
    cd 03-addons
    terraform init
    terraform plan
    terraform apply
    ;;
  applications)
    cd 04-applications
    terraform init
    terraform plan
    terraform apply
    ;;
  all)
    for dir in 01-network 02-eks 03-addons 04-applications; do
      echo "Deploying $dir..."
      cd "$dir"
      terraform init
      terraform plan
      terraform apply
      cd ..
    done
    ;;
  *)
    echo "Unknown component: $COMPONENT"
    exit 1
    ;;
esac

echo "Deployment completed successfully!"

