#!/bin/bash

echo "🛑 Stopping Kubedeploy EKS Microservices System..."

# Stop all services
docker-compose down --remove-orphans

# Remove unused volumes (optional)
read -p "🗑️  Remove database volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing volumes..."
    docker-compose down -v
    echo "✅ Volumes removed"
fi

echo "✅ System stopped successfully!"
