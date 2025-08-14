# SecureDocs Legal Platform Demo

A cloud-native legal document management platform deployed on Google Cloud Platform using Infrastructure as Code.

## Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# 1. Install prerequisites
chmod +x setup-prerequisites.sh
./setup-prerequisites.sh

# 2. Authenticate with GCP
gcloud auth login

# 3. Deploy everything
chmod +x deploy.sh
./deploy.sh your-project-id-here
```

### Option 2: Manual Step-by-Step

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed manual instructions.

## Prerequisites

- Google Cloud SDK (gcloud)
- Terraform >= 1.0
- kubectl
- GCP Project with billing enabled

## What Gets Deployed

- **GKE Cluster** - Private Kubernetes cluster (1-2 e2-micro nodes)
- **Cloud SQL** - PostgreSQL database (db-f1-micro)
- **VPC Network** - Private networking with security controls
- **Cloud Storage** - Document storage bucket
- **Load Balancer** - External access to the application
- **Demo Application** - Nginx-based legal platform interface

## Project Structure

```
├── terraform/              # Infrastructure as Code
│   ├── main.tf             # Main Terraform configuration
│   └── terraform.tfvars    # Variables (update project_id)
├── kubernetes/             # Kubernetes manifests
│   └── kubernetes-demo.yaml # Application deployment
├── deploy.sh              # Automated deployment script
├── setup-prerequisites.sh  # Tool installation script
├── cleanup.sh            # Resource cleanup script
├── DEPLOYMENT.md         # Detailed deployment guide
└── README.md            # This file
```

## Security Features

- ✅ Private GKE cluster with authorized networks
- ✅ Service accounts with minimal permissions
- ✅ No automount of service account tokens
- ✅ Encrypted storage buckets
- ✅ VPC with private IP ranges
- ✅ Firewall rules restricting access

## Cost Optimization

- Uses smallest instance types (e2-micro, db-f1-micro)
- Auto-scaling node pool (1-2 nodes)
- Storage lifecycle policies (30-day Nearline transition)
- Regional deployment for cost efficiency

## Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Project Access Issues**
   - Ensure project exists and billing is enabled
   - Verify you have Editor/Owner permissions

3. **API Not Enabled**
   ```bash
   gcloud services enable compute.googleapis.com container.googleapis.com storage.googleapis.com
   ```

4. **LoadBalancer IP Pending**
   ```bash
   kubectl get services -n securedocs --watch
   # Wait 2-3 minutes for IP assignment
   ```

### Verification Commands

```bash
# Check cluster
kubectl get nodes

# Check application
kubectl get pods -n securedocs
kubectl get services -n securedocs

# View logs
kubectl logs -l app=securedocs -n securedocs

# Get infrastructure details
cd terraform && terraform output
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace securedocs

# Destroy infrastructure
cd terraform && terraform destroy
```

Or use the cleanup script:
```bash
./cleanup.sh your-project-id
```

## Architecture

```
Internet → Load Balancer → GKE Cluster → Application Pods
                         ↓
                    Cloud SQL Database
                         ↓
                   Cloud Storage Bucket
```

## Technical Stack

- **Infrastructure**: Google Cloud Platform
- **Orchestration**: Google Kubernetes Engine (GKE)
- **Database**: Cloud SQL PostgreSQL
- **Storage**: Google Cloud Storage
- **IaC**: Terraform
- **Networking**: Private VPC with security controls

## Demo Features

The deployed application showcases:
- Cloud infrastructure deployment
- Kubernetes orchestration
- Security best practices
- Cost-optimized resource configuration
- Infrastructure monitoring capabilities

## Support

For issues or questions:
1. Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions
2. Review troubleshooting section above
3. Ensure all prerequisites are installed
4. Verify GCP project has billing enabled and proper permissions

---

**Author**: Jeffrey Egbagbe  
**Purpose**: GCP Administrator Demo for Lawlabs Inc.