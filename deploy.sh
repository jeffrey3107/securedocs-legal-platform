#!/bin/bash

# deploy.sh - Simple one-click deployment for SecureDocs demo
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_ID=$1

if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Usage: $0 <project-id>${NC}"
    echo "Example: $0 my-gcp-project"
    echo ""
    echo -e "${BLUE}For detailed manual instructions, see DEPLOYMENT.md${NC}"
    exit 1
fi

# Validate project ID format
if [[ ! "$PROJECT_ID" =~ ^[a-z][a-z0-9-]{4,28}[a-z0-9]$ ]]; then
    echo -e "${RED}❌ Invalid project ID format. Must be 6-30 characters, start with letter, contain only lowercase letters, numbers, and hyphens${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Deploying SecureDocs Legal Platform Demo${NC}"
echo "Project: $PROJECT_ID"
echo "=================================="

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install it first.${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found${NC}"

# Check if user is authenticated
echo -e "${BLUE}Checking GCP authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${RED}❌ No active GCP authentication found${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Check if project exists and user has access
if ! gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo -e "${RED}❌ Cannot access project $PROJECT_ID${NC}"
    echo "Please check:"
    echo "1. Project ID is correct"
    echo "2. You have access to the project"
    echo "3. Project exists and billing is enabled"
    exit 1
fi

echo -e "${GREEN}✅ GCP authentication verified${NC}"

# Set up GCP project
echo -e "${BLUE}Setting up GCP project...${NC}"
gcloud config set project $PROJECT_ID

# Check if application default credentials exist
if ! gcloud auth application-default print-access-token &>/dev/null; then
    echo -e "${BLUE}Setting up application default credentials...${NC}"
    echo "This will open a browser window for authentication."
    gcloud auth application-default login
fi

# Enable required APIs
echo -e "${BLUE}Enabling required APIs...${NC}"
gcloud services enable compute.googleapis.com container.googleapis.com storage.googleapis.com servicenetworking.googleapis.com --quiet

# Update terraform.tfvars
echo -e "${BLUE}Configuring Terraform...${NC}"
sed -i.bak "s/learning-458106/$PROJECT_ID/g" terraform/terraform.tfvars

# Verify the update
if ! grep -q "$PROJECT_ID" terraform/terraform.tfvars; then
    echo -e "${RED}❌ Failed to update terraform.tfvars${NC}"
    exit 1
fi

# Deploy infrastructure
echo -e "${BLUE}Deploying infrastructure with Terraform...${NC}"
cd terraform
terraform init
terraform validate

# Check for quota issues and provide helpful error messages
echo -e "${BLUE}Planning deployment...${NC}"
if ! terraform plan -out=tfplan; then
    echo -e "${RED}❌ Terraform plan failed. Common issues:${NC}"
    echo "1. Check your GCP quotas: https://console.cloud.google.com/iam-admin/quotas?project=$PROJECT_ID"
    echo "2. Ensure billing is enabled: https://console.cloud.google.com/billing?project=$PROJECT_ID"
    echo "3. Try running: gcloud auth application-default login"
    exit 1
fi

echo -e "${BLUE}Applying infrastructure changes...${NC}"
if ! terraform apply tfplan; then
    echo -e "${RED}❌ Terraform apply failed${NC}"
    echo "This might be due to:"
    echo "1. Resource quotas exceeded"
    echo "2. API permissions issues"
    echo "3. Resource conflicts"
    echo "Check the error message above for details."
    exit 1
fi

echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"

# Get cluster credentials
echo -e "${BLUE}Setting up kubectl...${NC}"
CLUSTER_NAME=$(terraform output -raw cluster_name)
gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1

# Deploy sample application
echo -e "${BLUE}Deploying sample application...${NC}"
cd ../kubernetes
kubectl apply -f kubernetes-demo.yaml

# Wait for deployment
echo -e "${BLUE}Waiting for application to be ready...${NC}"
if ! kubectl wait --for=condition=available --timeout=300s deployment/securedocs-demo -n securedocs; then
    echo -e "${RED}❌ Deployment failed to become ready${NC}"
    echo "Checking pod status..."
    kubectl get pods -n securedocs
    kubectl describe deployment securedocs-demo -n securedocs
    exit 1
fi

# Get service URL
echo -e "${BLUE}Getting application URL...${NC}"
kubectl get services securedocs-service -n securedocs

# Wait for LoadBalancer IP
echo -e "${BLUE}Waiting for LoadBalancer IP (this may take 2-3 minutes)...${NC}"
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get service securedocs-service -n securedocs -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "null" ]]; then
        echo -e "${GREEN}✅ LoadBalancer IP assigned: $EXTERNAL_IP${NC}"
        echo -e "${GREEN}🌐 Application URL: http://$EXTERNAL_IP${NC}"
        break
    fi
    echo "Waiting for IP... (attempt $i/30)"
    sleep 10
done

if [[ -z "$EXTERNAL_IP" || "$EXTERNAL_IP" == "null" ]]; then
    echo -e "${RED}⚠️  LoadBalancer IP still pending. Check status with:${NC}"
    echo "kubectl get services -n securedocs --watch"
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo "=================================="
echo -e "${BLUE}Demo Resources:${NC}"
cd ../terraform
terraform output

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Access your app: http://$EXTERNAL_IP (if IP is assigned)"
echo "2. GCP Console: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"
echo "3. Check pods: kubectl get pods -n securedocs"
echo "4. View logs: kubectl logs -l app=securedocs -n securedocs"
echo "5. Clean up: ./cleanup.sh $PROJECT_ID"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "• If LoadBalancer IP is pending: kubectl get services -n securedocs --watch"
echo "• For detailed logs: kubectl describe deployment securedocs-demo -n securedocs"
echo "• Manual instructions: cat DEPLOYMENT.md"

echo ""
echo -e "${GREEN}Demo is ready for your interview! 🚀${NC}"