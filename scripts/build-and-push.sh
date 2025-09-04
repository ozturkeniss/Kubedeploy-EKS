#!/bin/bash

set -e

echo "🐳 Building and pushing Docker images..."
echo "======================================="

# Configuration
AWS_REGION=${AWS_REGION:-"us-west-2"}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# Services to build
SERVICES=("user-service" "payment-service")

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Create ECR repositories if they don't exist
echo "📦 Creating ECR repositories..."
for service in "${SERVICES[@]}"; do
    aws ecr describe-repositories --repository-names ${service} --region ${AWS_REGION} 2>/dev/null || \
    aws ecr create-repository --repository-name ${service} --region ${AWS_REGION}
done

# Build and push images
for service in "${SERVICES[@]}"; do
    echo ""
    echo "🔨 Building ${service}..."
    
    # Build image
    docker build -f docker/Dockerfile.${service} -t ${service}:${IMAGE_TAG} .
    
    # Tag for ECR
    docker tag ${service}:${IMAGE_TAG} ${ECR_REGISTRY}/${service}:${IMAGE_TAG}
    
    # Push to ECR
    echo "📤 Pushing ${service} to ECR..."
    docker push ${ECR_REGISTRY}/${service}:${IMAGE_TAG}
    
    echo "✅ ${service} pushed successfully!"
done

echo ""
echo "🎉 All images built and pushed successfully!"
echo ""
echo "📋 Pushed images:"
for service in "${SERVICES[@]}"; do
    echo "   ${ECR_REGISTRY}/${service}:${IMAGE_TAG}"
done

# Update Kubernetes manifests with ECR images
echo ""
echo "🔧 Updating Kubernetes manifests..."
sed -i.bak "s|image: user-service:latest|image: ${ECR_REGISTRY}/user-service:${IMAGE_TAG}|g" kubernetes/deployments/user-service.yaml
sed -i.bak "s|image: payment-service:latest|image: ${ECR_REGISTRY}/payment-service:${IMAGE_TAG}|g" kubernetes/deployments/payment-service.yaml

echo "✅ Kubernetes manifests updated with ECR image URLs"
