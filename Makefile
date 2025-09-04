.PHONY: help start stop restart logs clean build test

# Default target
help: ## Show this help message
	@echo "Kubedeploy EKS Microservices System"
	@echo "==================================="
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ System Management
start: ## Start the entire system
	@./scripts/start-system.sh

stop: ## Stop the entire system
	@./scripts/stop-system.sh

restart: ## Restart the entire system
	@make stop
	@make start

##@ Development
build: ## Build all services
	@echo "🔨 Building services..."
	@docker-compose build

logs: ## Show logs for all services
	@docker-compose logs -f

logs-user: ## Show logs for user service
	@docker-compose logs -f user-service

logs-payment: ## Show logs for payment service
	@docker-compose logs -f payment-service

logs-gateway: ## Show logs for API gateway
	@docker-compose logs -f api-gateway

logs-db: ## Show logs for database
	@docker-compose logs -f postgres

##@ Testing
test-user: ## Test user service endpoints
	@echo "🧪 Testing User Service..."
	@curl -s http://localhost:8080/health && echo " ✅ User service health OK"
	@curl -s http://localhost:8000/api/users && echo " ✅ User API via gateway OK"

test-payment: ## Test payment service endpoints
	@echo "🧪 Testing Payment Service..."
	@curl -s http://localhost:8081/health && echo " ✅ Payment service health OK"
	@curl -s http://localhost:8000/api/payments && echo " ✅ Payment API via gateway OK"

test-gateway: ## Test API gateway
	@echo "🧪 Testing API Gateway..."
	@curl -s http://localhost:8000/health && echo " ✅ Gateway health OK"

test: ## Run all tests
	@make test-user
	@make test-payment
	@make test-gateway

##@ Maintenance
clean: ## Clean up containers, images, and volumes
	@echo "🧹 Cleaning up..."
	@docker-compose down -v --remove-orphans
	@docker system prune -f

status: ## Show status of all services
	@docker-compose ps

##@ AWS Deployment
deploy-aws: ## Deploy to AWS EKS
	@./scripts/deploy-aws.sh

build-push: ## Build and push Docker images to ECR
	@./scripts/build-and-push.sh

cleanup-aws: ## Cleanup AWS resources
	@./scripts/cleanup-aws.sh

##@ Terraform
tf-init: ## Initialize Terraform
	@cd terraform && terraform init

tf-plan: ## Plan Terraform infrastructure
	@cd terraform && terraform plan

tf-apply: ## Apply Terraform infrastructure
	@cd terraform && terraform apply

tf-destroy: ## Destroy Terraform infrastructure
	@cd terraform && terraform destroy

##@ Kubernetes
k8s-deploy: ## Deploy to existing Kubernetes cluster
	@kubectl apply -f kubernetes/namespaces/
	@kubectl apply -f kubernetes/configmaps/
	@kubectl apply -f kubernetes/secrets/
	@kubectl apply -f kubernetes/deployments/
	@kubectl apply -f kubernetes/services/

k8s-status: ## Check Kubernetes deployment status
	@kubectl get pods -n kubedeploy
	@kubectl get services -n kubedeploy

k8s-logs: ## Show logs from all pods
	@kubectl logs -l app=user-service -n kubedeploy --tail=100
	@kubectl logs -l app=payment-service -n kubedeploy --tail=100
	@kubectl logs -l app=krakend -n kubedeploy --tail=100

##@ Scripts
setup: ## Setup executable permissions for scripts
	@chmod +x scripts/*.sh
	@echo "✅ Script permissions set"
