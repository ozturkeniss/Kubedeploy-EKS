#!/bin/bash

echo "🚀 Starting Kubedeploy EKS Microservices System..."
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: docker-compose not found!"
    echo "Please install docker-compose to continue."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "Please start Docker and try again."
    exit 1
fi

echo "📋 System Components:"
echo "  🐘 PostgreSQL Database (Port 5432)"
echo "  👤 User Service (HTTP: 8080, gRPC: 9091)"
echo "  💳 Payment Service (HTTP: 8081)"
echo "  🌐 API Gateway (KrakenD: 8000)"
echo ""

# Stop any existing containers
echo "🧹 Cleaning up existing containers..."
docker-compose down --remove-orphans

# Build and start services
echo "🔨 Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL is not ready"
fi

# Check User Service
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ User Service is ready"
else
    echo "❌ User Service is not ready"
fi

# Check Payment Service
if curl -s http://localhost:8081/health >/dev/null 2>&1; then
    echo "❌ Payment Service is not ready"
else
    echo "✅ Payment Service is ready"
fi

# Check API Gateway
if curl -s http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ API Gateway is ready"
else
    echo "❌ API Gateway is not ready"
fi

echo ""
echo "🎉 System startup complete!"
echo ""
echo "📡 Available endpoints:"
echo "  API Gateway: http://localhost:8000"
echo "  - Health: GET http://localhost:8000/health"
echo "  - Users: GET/POST/PUT/DELETE http://localhost:8000/api/users"
echo "  - Payments: GET/POST http://localhost:8000/api/payments"
echo "  - Dashboard: GET http://localhost:8000/api/dashboard"
echo ""
echo "🔧 Management commands:"
echo "  - View logs: docker-compose logs -f [service-name]"
echo "  - Stop system: docker-compose down"
echo "  - Restart: docker-compose restart [service-name]"
echo ""
echo "📊 Direct service access (development only):"
echo "  - User Service: http://localhost:8080"
echo "  - Payment Service: http://localhost:8081"
