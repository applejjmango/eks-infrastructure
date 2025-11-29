#!/bin/bash
# Backup Terraform state script

set -e

ENVIRONMENT="${1:-dev}"
S3_BUCKET="${2:-your-terraform-state-bucket}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <environment> [s3-bucket]"
  exit 1
fi

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/terraform-state-backup-$BACKUP_DATE"

mkdir -p "$BACKUP_DIR"

cd "$(dirname "$0")/../environments/$ENVIRONMENT"

echo "Backing up Terraform state for environment: $ENVIRONMENT"

for dir in 01-network 02-eks 03-addons 04-applications; do
  if [ -d "$dir" ] && [ -f "$dir/.terraform/terraform.tfstate" ]; then
    echo "Backing up $dir..."
    cp -r "$dir" "$BACKUP_DIR/"
  fi
done

# Optionally upload to S3
if [ -n "$S3_BUCKET" ]; then
  echo "Uploading backup to S3..."
  aws s3 cp "$BACKUP_DIR" "s3://$S3_BUCKET/backups/$ENVIRONMENT/$BACKUP_DATE/" --recursive
fi

echo "Backup completed: $BACKUP_DIR"

