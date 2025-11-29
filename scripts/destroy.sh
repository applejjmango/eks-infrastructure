#!/bin/bash
# Destruction script for EKS infrastructure

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
    terraform destroy
    ;;
  eks)
    cd 02-eks
    terraform destroy
    ;;
  addons)
    cd 03-addons
    terraform destroy
    ;;
  applications)
    cd 04-applications
    terraform destroy
    ;;
  all)
    # Destroy in reverse order
    for dir in 04-applications 03-addons 02-eks 01-network; do
      echo "Destroying $dir..."
      cd "$dir"
      terraform destroy
      cd ..
    done
    ;;
  *)
    echo "Unknown component: $COMPONENT"
    exit 1
    ;;
esac

echo "Destruction completed successfully!"

