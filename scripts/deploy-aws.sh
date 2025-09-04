#!/bin/bash

set -e

echo "🚀 Deploying Kubedeploy EKS to AWS..."
echo "=================================="

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"kubedeploy-eks"}
AWS_REGION=${AWS_REGION:-"us-west-2"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed!"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed!"
    exit 1
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed!"
    exit 1
fi

# Check Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ Ansible is not installed!"
    exit 1
fi

echo "✅ All prerequisites are installed"

# Deploy infrastructure with Terraform
echo ""
echo "🏗️ Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
fi

# Plan infrastructure
echo "📋 Planning infrastructure..."
terraform plan -var="cluster_name=${CLUSTER_NAME}" \
               -var="region=${AWS_REGION}" \
               -var="environment=${ENVIRONMENT}" \
               -out=tfplan

# Apply infrastructure
echo "🔨 Applying infrastructure..."
terraform apply tfplan

# Get outputs
CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
CLUSTER_NAME_OUTPUT=$(terraform output -raw cluster_name)

echo "✅ Infrastructure deployed successfully!"
echo "   Cluster Name: ${CLUSTER_NAME_OUTPUT}"
echo "   Cluster Endpoint: ${CLUSTER_ENDPOINT}"

cd ..

# Update kubeconfig
echo ""
echo "🔧 Updating kubeconfig..."
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME_OUTPUT}

# Build and push Docker images
echo ""
echo "🐳 Building and pushing Docker images..."
./scripts/build-and-push.sh

# Deploy application with Ansible
echo ""
echo "🎭 Deploying application with Ansible..."
cd ansible

ansible-playbook -i inventories/aws.yml \
                 playbooks/deploy.yml \
                 -e cluster_name=${CLUSTER_NAME_OUTPUT} \
                 -e aws_region=${AWS_REGION} \
                 -e environment=${ENVIRONMENT}

cd ..

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Useful commands:"
echo "   kubectl get pods -n kubedeploy"
echo "   kubectl get services -n kubedeploy"
echo "   kubectl logs -f deployment/krakend -n kubedeploy"
echo ""
echo "🌐 To get the API Gateway URL:"
echo "   kubectl get service krakend-service -n kubedeploy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
