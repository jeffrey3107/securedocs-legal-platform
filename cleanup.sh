#!/bin/bash

# cleanup.sh - Clean up SecureDocs demo resources
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ID=$1

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Usage: $0 <project-id>${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will destroy ALL demo resources!${NC}"
echo "Project: $PROJECT_ID"
read -p "Type 'yes' to continue: " confirm

if [[ $confirm != "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "${YELLOW}🧹 Cleaning up SecureDocs demo resources...${NC}"

# Set project
gcloud config set project $PROJECT_ID

# Destroy Terraform infrastructure (ignore API disable errors)
echo -e "${YELLOW}Destroying infrastructure...${NC}"
cd terraform

# Modify the terraform file to not disable APIs on destroy
sed -i.bak 's/disable_on_destroy = true/disable_on_destroy = false/g' main.tf

terraform destroy -auto-approve

# Restore the original file
if [[ -f main.tf.bak ]]; then
    mv main.tf.bak main.tf
fi

echo -e "${GREEN}✅ Cleanup completed!${NC}"
echo "All demo resources have been removed from project: $PROJECT_ID"
echo -e "${YELLOW}Note: APIs are left enabled to avoid dependency issues${NC}"