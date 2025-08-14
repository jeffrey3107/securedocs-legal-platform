#!/bin/bash

# setup-prerequisites.sh - Install prerequisites for SecureDocs demo
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}🛠️  SecureDocs Prerequisites Setup${NC}"
echo "This script will help you install the required tools."
echo "=================================="

# Detect OS
OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Darwin*)
        PLATFORM="macOS"
        ;;
    Linux*)
        PLATFORM="Linux"
        ;;
    *)
        echo -e "${RED}❌ Unsupported operating system: $OS${NC}"
        exit 1
        ;;
esac

echo -e "${BLUE}Detected platform: $PLATFORM ($ARCH)${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install via Homebrew (macOS)
install_with_brew() {
    if ! command_exists brew; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install "$1"
}

# Check and install gcloud
echo -e "${BLUE}Checking Google Cloud SDK...${NC}"
if command_exists gcloud; then
    echo -e "${GREEN}✅ gcloud is already installed${NC}"
    gcloud version
else
    echo -e "${YELLOW}Installing Google Cloud SDK...${NC}"
    if [[ "$PLATFORM" == "macOS" ]]; then
        if command_exists brew; then
            brew install --cask google-cloud-sdk
        else
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        fi
    elif [[ "$PLATFORM" == "Linux" ]]; then
        curl https://sdk.cloud.google.com | bash
        exec -l $SHELL
    fi
    echo -e "${GREEN}✅ Google Cloud SDK installed${NC}"
fi

# Check and install Terraform
echo -e "${BLUE}Checking Terraform...${NC}"
if command_exists terraform; then
    echo -e "${GREEN}✅ Terraform is already installed${NC}"
    terraform version
else
    echo -e "${YELLOW}Installing Terraform...${NC}"
    if [[ "$PLATFORM" == "macOS" ]]; then
        install_with_brew hashicorp/tap/terraform
    elif [[ "$PLATFORM" == "Linux" ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi
    echo -e "${GREEN}✅ Terraform installed${NC}"
fi

# Check and install kubectl
echo -e "${BLUE}Checking kubectl...${NC}"
if command_exists kubectl; then
    echo -e "${GREEN}✅ kubectl is already installed${NC}"
    kubectl version --client
else
    echo -e "${YELLOW}Installing kubectl...${NC}"
    if [[ "$PLATFORM" == "macOS" ]]; then
        if [[ "$ARCH" == "arm64" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
        else
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
        fi
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    elif [[ "$PLATFORM" == "Linux" ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi
    echo -e "${GREEN}✅ kubectl installed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 All prerequisites installed successfully!${NC}"
echo "=================================="
echo -e "${BLUE}Next steps:${NC}"
echo "1. Create or select a GCP project"
echo "2. Run: gcloud auth login"
echo "3. Run: ./deploy.sh your-project-id"
echo ""
echo -e "${BLUE}Tool versions:${NC}"
gcloud version --quiet 2>/dev/null | head -1 || echo "gcloud: not found"
terraform version | head -1 2>/dev/null || echo "terraform: not found"
kubectl version --client --short 2>/dev/null || echo "kubectl: not found"