# Kubedeploy EKS

Production-ready microservices architecture built with Go, gRPC, PostgreSQL, and KrakenD API Gateway, designed for deployment on AWS EKS.

## Architecture

```mermaid
graph TB
    Client[Client Applications]
    
    subgraph "AWS Cloud"
        subgraph "EKS Cluster"
            subgraph "Ingress Layer"
                ALB[Application Load Balancer]
                Ingress[Kubernetes Ingress]
            end
            
            subgraph "API Gateway Layer"
                KrakenD[KrakenD API Gateway<br/>Port: 8000]
            end
            
            subgraph "Microservices Layer"
                UserSvc[User Service<br/>HTTP: 8080<br/>gRPC: 9091]
                PaymentSvc[Payment Service<br/>HTTP: 8081]
            end
            
            subgraph "Data Layer"
                PostgreSQL[PostgreSQL Database<br/>Port: 5432]
                PVC[Persistent Volume]
            end
        end
    end
    
    Client --> ALB
    ALB --> Ingress
    Ingress --> KrakenD
    KrakenD --> UserSvc
    KrakenD --> PaymentSvc
    PaymentSvc -.->|gRPC| UserSvc
    UserSvc --> PostgreSQL
    PaymentSvc --> PostgreSQL
    PostgreSQL --> PVC
    
    classDef client fill:#2E3440,stroke:#88C0D0,stroke-width:2px,color:#ECEFF4
    classDef aws fill:#4C566A,stroke:#5E81AC,stroke-width:2px,color:#ECEFF4
    classDef gateway fill:#5E81AC,stroke:#81A1C1,stroke-width:2px,color:#ECEFF4
    classDef service fill:#8FBCBB,stroke:#88C0D0,stroke-width:2px,color:#2E3440
    classDef database fill:#BF616A,stroke:#D08770,stroke-width:2px,color:#ECEFF4
    
    class Client client
    class ALB,Ingress aws
    class KrakenD gateway
    class UserSvc,PaymentSvc service
    class PostgreSQL,PVC database
```

## Deployment Flow

```mermaid
flowchart LR
    A[Source Code] --> B[Docker Build]
    B --> C[ECR Push]
    C --> D[Terraform Apply]
    D --> E[EKS Cluster]
    E --> F[Ansible Deploy]
    F --> G[Running Application]
    
    classDef source fill:#2E3440,stroke:#88C0D0,stroke-width:2px,color:#ECEFF4
    classDef build fill:#4C566A,stroke:#5E81AC,stroke-width:2px,color:#ECEFF4
    classDef deploy fill:#5E81AC,stroke:#81A1C1,stroke-width:2px,color:#ECEFF4
    classDef infra fill:#8FBCBB,stroke:#88C0D0,stroke-width:2px,color:#2E3440
    classDef app fill:#BF616A,stroke:#D08770,stroke-width:2px,color:#ECEFF4
    
    class A source
    class B,C build
    class D,F deploy
    class E infra
    class G app
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- AWS CLI (for EKS deployment)
- Terraform (for infrastructure)
- kubectl (for Kubernetes management)

### Local Development
```bash
make start          # Start local environment
make test          # Run API tests
make stop          # Stop local environment
```

### AWS EKS Deployment
```bash
make deploy-aws    # Full automated deployment
```

## API Endpoints

All requests go through the API Gateway at `http://localhost:8000`

### Users API
```bash
# Get all users
GET http://localhost:8000/api/users

# Create a user
POST http://localhost:8000/api/users
Content-Type: application/json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "password123"
}

# Get user by ID
GET http://localhost:8000/api/users/{id}

# Update user
PUT http://localhost:8000/api/users/{id}
Content-Type: application/json
{
  "username": "newusername",
  "email": "newemail@example.com"
}

# Delete user
DELETE http://localhost:8000/api/users/{id}
```

### Payments API
```bash
# Get all payments
GET http://localhost:8000/api/payments

# Create a payment
POST http://localhost:8000/api/payments
Content-Type: application/json
{
  "user_id": 1,
  "amount": 99.99,
  "currency": "USD",
  "description": "Product purchase"
}

# Get payment by ID
GET http://localhost:8000/api/payments/{id}

# Get user's payments
GET http://localhost:8000/api/payments/user/{userId}
```

### Dashboard API
```bash
# Get dashboard data (users + payments)
GET http://localhost:8000/api/dashboard
```

## Development

### Available Make Commands
```bash
# Local Development
make start          # Start the entire system
make stop           # Stop the entire system
make test           # Run all tests
make build          # Build all services

# AWS Deployment
make deploy-aws     # Full AWS deployment
make build-push     # Build & push to ECR
make cleanup-aws    # Destroy everything

# Kubernetes Operations
make k8s-deploy     # Deploy to K8s
make k8s-status     # Check status
make k8s-logs       # View logs

# Terraform Operations
make tf-plan        # Plan infrastructure
make tf-apply       # Apply infrastructure
make tf-destroy     # Destroy infrastructure
```

### Direct Service Access (Development Only)
- User Service: `http://localhost:8080`
- Payment Service: `http://localhost:8081`
- PostgreSQL: `localhost:5432` (user: postgres, password: postgres, db: userdb)

## Project Structure

```mermaid
graph TD
    subgraph "Source Code"
        A[cmd/] --> A1[user-service/]
        A[cmd/] --> A2[payment-service/]
        
        B[internal/] --> B1[user/]
        B[internal/] --> B2[payment/]
        
        C[api/proto/] --> C1[user/]
        
        D[pkg/] --> D1[config/]
        D[pkg/] --> D2[database/]
    end
    
    subgraph "Infrastructure"
        E[terraform/] --> E1[main.tf]
        E[terraform/] --> E2[variables.tf]
        E[terraform/] --> E3[outputs.tf]
        
        F[kubernetes/] --> F1[deployments/]
        F[kubernetes/] --> F2[services/]
        F[kubernetes/] --> F3[configmaps/]
        
        G[ansible/] --> G1[playbooks/]
        G[ansible/] --> G2[roles/]
    end
    
    subgraph "Deployment"
        H[docker/] --> H1[Dockerfile.user]
        H[docker/] --> H2[Dockerfile.payment]
        
        I[scripts/] --> I1[deploy-aws.sh]
        I[scripts/] --> I2[build-and-push.sh]
        I[scripts/] --> I3[cleanup-aws.sh]
    end
    
    classDef source fill:#2E3440,stroke:#88C0D0,stroke-width:2px,color:#ECEFF4
    classDef infra fill:#4C566A,stroke:#5E81AC,stroke-width:2px,color:#ECEFF4
    classDef deploy fill:#5E81AC,stroke:#81A1C1,stroke-width:2px,color:#ECEFF4
    
    class A,B,C,D,A1,A2,B1,B2,C1,D1,D2 source
    class E,F,G,E1,E2,E3,F1,F2,F3,G1,G2 infra
    class H,I,H1,H2,I1,I2,I3 deploy
```

## Technology Stack

- **Backend**: Go 1.23, gRPC, PostgreSQL 15, GORM
- **API Gateway**: KrakenD 2.7
- **Infrastructure**: AWS EKS, Terraform, Ansible
- **Containerization**: Docker, Kubernetes
- **Architecture**: Clean Architecture, Microservices

## Infrastructure Overview

```mermaid
graph TB
    subgraph "AWS Infrastructure"
        subgraph "VPC"
            subgraph "Public Subnets"
                NAT[NAT Gateway]
                ALB[Application Load Balancer]
            end
            
            subgraph "Private Subnets"
                subgraph "EKS Cluster"
                    Master[EKS Control Plane]
                    
                    subgraph "Worker Nodes"
                        Node1[t3.medium]
                        Node2[t3.medium]
                    end
                    
                    subgraph "Pods"
                        UserPod[User Service Pods]
                        PaymentPod[Payment Service Pods]
                        KrakendPod[KrakenD Pods]
                        PostgresPod[PostgreSQL Pod]
                    end
                end
            end
        end
        
        subgraph "AWS Services"
            ECR[Elastic Container Registry]
            EBS[Elastic Block Store]
            IAM[IAM Roles & Policies]
        end
    end
    
    Internet --> ALB
    ALB --> KrakendPod
    KrakendPod --> UserPod
    KrakendPod --> PaymentPod
    PaymentPod -.->|gRPC| UserPod
    UserPod --> PostgresPod
    PaymentPod --> PostgresPod
    PostgresPod --> EBS
    
    ECR -.-> UserPod
    ECR -.-> PaymentPod
    IAM -.-> Master
    NAT -.-> Node1
    NAT -.-> Node2
    
    classDef aws fill:#FF9900,stroke:#FF6600,stroke-width:2px,color:#FFFFFF
    classDef eks fill:#326CE5,stroke:#1E4A72,stroke-width:2px,color:#FFFFFF
    classDef pod fill:#48C9B0,stroke:#16A085,stroke-width:2px,color:#FFFFFF
    classDef storage fill:#E74C3C,stroke:#C0392B,stroke-width:2px,color:#FFFFFF
    
    class ECR,EBS,IAM,ALB,NAT aws
    class Master,Node1,Node2 eks
    class UserPod,PaymentPod,KrakendPod,PostgresPod pod
    class EBS storage
```

## Production Deployment

The system is designed for production deployment on AWS EKS with:

- High availability across multiple AZs
- Auto-scaling worker nodes
- Persistent storage for PostgreSQL
- Load balancing with AWS ALB
- Container registry with ECR
- Infrastructure as Code with Terraform
- Automated deployment with Ansible


