# Project Bedrock: Enterprise Retail EKS Cluster 
**Capstone Project ID:** `barakat-2025-capstone`

## 📖 Table of Contents
1. [Executive Summary](#-executive-summary)
2. [Architecture Deep Dive](#-architecture-deep-dive)
3. [Infrastructure as Code (IaC)](#-infrastructure-as-code-iac)
4. [CI/CD Pipeline Workflow](#-cicd-pipeline-workflow)
5. [Kubernetes Orchestration](#-kubernetes-orchestration)
6. [Data Layer & Serverless](#-data-layer--serverless)
7. [Deployment & Cleanup](#-deployment--cleanup)

---

## 🚀 Executive Summary
Project Bedrock is a production-grade deployment of a microservices-based Retail Store. It utilizes **Terraform** for reproducible infrastructure, **GitHub Actions** for continuous delivery, and **Amazon EKS** for container orchestration. 

**Live Environment:** [PASTE_YOUR_RETAIL_UI_URL_HERE]

---

## 🏗️ Architecture Deep Dive


### 🌐 Networking & Security
- **VPC Design:** A custom VPC spanning multiple Availability Zones (AZs) to ensure high availability.
- **Subnet Strategy:** - **Public Subnets:** Host the Application Load Balancers (ALB) and Internet Gateway.
  - **Private Subnets:** Host EKS Worker Nodes (EC2 instances). This prevents direct internet exposure of the compute layer.
- **Security Groups:** Minimum privilege rules allowing only Port 80/443 traffic from the ELB to the Node groups.

### ☸️ Compute (EKS)
- **Managed Control Plane:** AWS-managed Kubernetes master nodes.
- **Managed Node Groups:** Automated scaling and patching of worker nodes.
- **Namespacing:** Logical separation of environments (`default`, `retail-app`, `kube-system`).

---

## 🛠️ Infrastructure as Code (IaC)
The `/terraform` directory contains:
- `vpc.tf`: Defines the network skeleton (IGW, NAT, Routing tables).
- `eks.tf`: Provisions the cluster and OIDC providers for IAM roles for service accounts (IRSA).
- `outputs.tf`: Exports critical metadata for the `grading.json` file.
- `backend.tf`: Configures remote state locking in **Amazon S3** to prevent state corruption.

---

## 🔄 CI/CD Pipeline Workflow
The `.github/workflows/terraform.yml` pipeline automates the entire lifecycle:
1. **Validation:** Runs `terraform fmt` and `terraform validate`.
2. **Planning:** Generates an execution plan to preview changes.
3. **Deployment:** Executes `terraform apply` on merge to the `master` branch.
4. **Manual Trigger:** Supports `workflow_dispatch` allowing for manual `apply` or `destroy` actions via the GitHub UI.

---

## 📦 Kubernetes Orchestration
The application is deployed using standard Kubernetes manifests:
- **Deployments:** Manages the desired state for the Retail UI and Catalog pods.
- **Services:** `LoadBalancer` type services interface with AWS ELB to provide stable DNS endpoints.
- **Scaling:** Replicas are distributed across nodes to handle traffic spikes.

---

## ⚡ Data Layer & Serverless
- **Event-Driven Processing:** An **S3 Bucket** acts as a landing zone for data.
- **AWS Lambda:** Triggered by `S3:ObjectCreated` events to process incoming JSON/CSV data.
- **Persistence:** Interacts with a MySQL/Postgres backend managed within the `retail-app` namespace.

---

## 🛠️ Deployment & Cleanup
### **To Deploy:**
1. Push code to `master` or manually run the GitHub Action with the `apply` input.
2. Run `kubectl get svc` to retrieve the LoadBalancer URL.

### **To Teardown:**
1. Manually run the GitHub Action with the `destroy` input to remove all AWS resources and stop billing.

---
**Maintained by:** Loveth20  
**Project Status:** Active / Grade Pending
