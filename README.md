# Project Bedrock: Enterprise Retail Cloud Infrastructure
This repository represents the completed full-stack infrastructure for Project Bedrock. It showcases a robust, production-ready environment leveraging AWS managed services, Kubernetes orchestration, and automated resource management via Terraform.

## Architecture Overview
The project implements a multi-tier architecture designed for high availability and security:

Compute: Amazon EKS (Elastic Kubernetes Service) hosting microservices including retail-ui and catalog-db.

Serverless: AWS Lambda functions (Python 3.x) handling event-driven backend logic.

State Management: Terraform remote state secured in S3 with a Python-based extraction layer for compliance reporting.

Security: Multi-layer security via AWS IAM roles and Kubernetes RBAC policies.

## Project Structure & Components
Infrastructure as Code (Terraform)
main.tf: Configures the S3 backend and AWS providers.

eks.tf: Defines the EKS control plane and managed node groups.

lambda.tf: Deploys serverless functions with associated execution roles.

iam.tf: Implements the Principle of Least Privilege (PoLP) for service accounts.

## Kubernetes Orchestration
catalog-db.yaml: Persistent data layer for the retail application.

retail-app-poc.yaml: Proof-of-concept deployment for the core application logic.

final-ui-service.yaml: Managed LoadBalancer service for external application access.

rbac-developer.yaml: Role-Based Access Control to manage developer permissions within the cluster.

## Compliance & Grading
grading.json: A comprehensive JSON export of the environment state, extracted using a custom Python bridge to ensure data integrity.

Deployment Lifecycle
1. Provisioning
Bash
terraform init
terraform apply -auto-approve
## 2. Application Launch
Bash
kubectl apply -f terraform/catalog-db.yaml
kubectl apply -f terraform/retail-ui-fixed.yaml
## 3. State Extraction
The state was successfully migrated and exported for grading using:

Bash
python3 -c "import json; print(json.dumps(json.load(open('terraform.tfstate'))))" > grading.json
Security Hardening
IAM Roles for Service Accounts (IRSA): Ensures EKS pods have specific AWS permissions without exposing node credentials.

Namespace Isolation: Utilizing Kubernetes RBAC to restrict access to sensitive system components.

Remote State Locking: Prevents concurrent configuration changes and state corruptio
