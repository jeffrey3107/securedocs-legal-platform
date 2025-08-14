# SecureDocs Demo Deployment Guide

## Prerequisites

Before deploying, ensure you have:

1. **Google Cloud SDK (gcloud)** - [Install Guide](https://cloud.google.com/sdk/docs/install)
2. **Terraform** - [Install Guide](https://developer.hashicorp.com/terraform/downloads)
3. **kubectl** - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
4. **GCP Project** with billing enabled

## Quick Setup Commands

```bash
# Install gcloud (macOS)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install terraform (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Install kubectl (macOS)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

## Manual Deployment Steps

### Step 1: GCP Authentication & Project Setup

```bash
# Set your project ID
export PROJECT_ID="your-project-id-here"

# Authenticate with GCP
gcloud auth login
gcloud config set project $PROJECT_ID

# Set up application default credentials
gcloud auth application-default login

# Enable required APIs (may take a few minutes)
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### Step 2: Configure Terraform

```bash
cd terraform

# Update terraform.tfvars with your project ID
sed -i.bak "s/learning-458106/$PROJECT_ID/g" terraform.tfvars

# Verify the configuration
cat terraform.tfvars
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the infrastructure (takes 5-10 minutes)
terraform apply

# Type 'yes' when prompted
```

### Step 4: Deploy Application

```bash
# Get cluster credentials
CLUSTER_NAME=$(terraform output -raw cluster_name)
gcloud container clusters get-credentials $CLUSTER_NAME --region us-central1

# Verify cluster connection
kubectl cluster-info

# Deploy the application
cd ../kubernetes
kubectl apply -f kubernetes-demo.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/securedocs-demo -n securedocs

# Get the external IP (may take 2-3 minutes)
kubectl get services -n securedocs
```

### Step 5: Access Your Application

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get service securedocs-service -n securedocs -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application URL: http://$EXTERNAL_IP"

# Test the application
curl http://$EXTERNAL_IP
```

## Automated Deployment (One Command)

```bash
# Make the script executable and run
chmod +x deploy.sh
./deploy.sh your-project-id-here
```

## Troubleshooting

### Common Issues:

1. **Authentication Errors**
   ```bash
   gcloud auth application-default login
   gcloud config set project $PROJECT_ID
   ```

2. **API Not Enabled**
   ```bash
   gcloud services enable compute.googleapis.com container.googleapis.com storage.googleapis.com
   ```

3. **Quota Exceeded**
   - Check quotas: https://console.cloud.google.com/iam-admin/quotas
   - Request quota increases if needed

4. **Billing Not Enabled**
   - Enable billing: https://console.cloud.google.com/billing

5. **LoadBalancer IP Pending**
   ```bash
   # Wait a few minutes, then check again
   kubectl get services -n securedocs --watch
   ```

### Verification Commands

```bash
# Check cluster status
kubectl get nodes

# Check pods
kubectl get pods -n securedocs

# Check services
kubectl get services -n securedocs

# View application logs
kubectl logs -l app=securedocs -n securedocs

# Get terraform outputs
cd terraform && terraform output
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace securedocs

# Destroy infrastructure
cd terraform
terraform destroy

# Type 'yes' when prompted
```

## Project Structure

```
securedocs-demo/
├── terraform/          # Infrastructure as Code
│   ├── main.tf         # Main Terraform configuration
│   └── terraform.tfvars # Variables (edit this file)
├── kubernetes/         # Kubernetes manifests
│   └── kubernetes-demo.yaml # Application deployment
├── deploy.sh          # Automated deployment script
├── cleanup.sh         # Cleanup script
└── DEPLOYMENT.md      # This file
```

## Resource Overview

This deployment creates:
- **GKE Cluster** (1-2 nodes, e2-micro instances)
- **Cloud SQL PostgreSQL** database (db-f1-micro)
- **VPC Network** with private subnets
- **Cloud Storage** bucket for documents
- **Load Balancer** for web access
- **Firewall Rules** for security

## Security Features

- Private GKE cluster
- Service account with minimal permissions
- No automount of service account tokens
- Encrypted storage
- VPC with private IP ranges
- Firewall rules restricting access

## Cost Optimization

- Uses smallest instance types (e2-micro, db-f1-micro)
- Auto-scaling node pool (1-2 nodes)
- Storage lifecycle policies
- Regional deployment for cost efficiency

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify prerequisites are installed
3. Ensure GCP project has billing enabled
4. Check GCP quotas and permissions