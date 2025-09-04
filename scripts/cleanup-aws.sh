#!/bin/bash

set -e

echo "🧹 Cleaning up AWS resources..."
echo "==============================="

# Configuration
CLUSTER_NAME=${CLUSTER_NAME:-"kubedeploy-eks"}
AWS_REGION=${AWS_REGION:-"us-west-2"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Confirm cleanup
read -p "⚠️  This will destroy ALL AWS resources. Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete Kubernetes resources first
echo ""
echo "🗑️ Deleting Kubernetes resources..."
kubectl delete namespace kubedeploy --ignore-not-found=true

# Wait for namespace deletion
echo "⏳ Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/kubedeploy --timeout=300s || true

# Delete ECR repositories
echo ""
echo "🗑️ Deleting ECR repositories..."
SERVICES=("user-service" "payment-service")

for service in "${SERVICES[@]}"; do
    echo "Deleting ECR repository: ${service}"
    aws ecr delete-repository --repository-name ${service} --region ${AWS_REGION} --force 2>/dev/null || true
done

# Destroy infrastructure with Terraform
echo ""
echo "🏗️ Destroying infrastructure with Terraform..."
cd terraform

# Destroy infrastructure
terraform destroy -var="cluster_name=${CLUSTER_NAME}" \
                 -var="region=${AWS_REGION}" \
                 -auto-approve

cd ..

# Clean up local Docker images
echo ""
echo "🐳 Cleaning up local Docker images..."
docker images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(user-service|payment-service)" | awk '{print $1}' | xargs -r docker rmi -f 2>/dev/null || true

# Clean up kubeconfig context
echo ""
echo "🔧 Cleaning up kubeconfig..."
kubectl config delete-context arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${CLUSTER_NAME} 2>/dev/null || true

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "🗂️ What was cleaned up:"
echo "   ✓ EKS cluster and node groups"
echo "   ✓ VPC and networking resources"
echo "   ✓ ECR repositories"
echo "   ✓ Local Docker images"
echo "   ✓ Kubernetes context"
echo ""
echo "💡 Note: S3 bucket for Terraform state (if used) was not deleted"
