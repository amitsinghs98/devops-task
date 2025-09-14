````markdown
````
# 🚀 Node.js App on AWS Fargate with CI/CD Pipeline
Note:
We are using a Multibranch Jenkins Pipeline with two branches:

dev branch → Runs terraform plan only.

This helps us detect and fix any infrastructure errors safely before applying changes.

main branch → Runs terraform apply.

Once a Pull Request (PR) from dev to main is merged, the pipeline automatically applies the changes.

This is triggered by a GitHub webhook (push event), ensuring that deployments to AWS Fargate are automated and consistent.


````
## 📚 Table of Contents
````
- [Getting Started](#getting-started)
- [How to Deploy](#how-to-deploy)
- [🛠️ Tools & Services Used](#️-tools--services-used)
- [📐 Architecture Diagram](#-architecture-diagram)
- [⚡ Challenges Faced & Solutions](#-challenges-faced--solutions)
- [🚀 Possible Improvements](#-possible-improvements)

````
## 🧰 Getting Started

### Prerequisites

- Node.js ≥ v16
- Docker
- Terraform ≥ v1.3
- AWS CLI
- Jenkins (with plugins: Git, Docker, AWS, Pipeline)
- AWS account with access to ECS, ECR, CloudWatch, IAM, S3, DynamoDB
````
### Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/your-username/your-repo.git
cd your-repo
````

#### 2. Configure AWS Credentials

```bash
aws configure
```

#### 3. Set Up Terraform Backend

Create an S3 bucket and DynamoDB table for remote state and locking.

#### 4. Initialize Terraform

```bash
cd terraform/
terraform init
```

---

## 🚀 How to Deploy

### CI/CD Flow via Jenkins

1. **Push Code to GitHub**
   GitHub webhook triggers the Jenkins pipeline.

2. **Pipeline Steps (Automated)**

   * Install dependencies
   * Lint and analyze code with SonarQube
   * Dockerize the application
   * Run Trivy scan
   * Push image to AWS ECR
   * On `main` branch: Apply Terraform to deploy app

3. **Access Application**
   Once deployed, the Node.js app runs in ECS (Fargate) and is accessible via Load Balancer or public IP.

---

## 🛠️ Tools & Services Used

* **GitHub** → Version control, branching (`main`, `dev`)
* **Jenkins** → CI/CD automation
* **Docker** → App containerization
* **Trivy** → Docker image vulnerability scanning
* **SonarQube** → Code quality and linting
* **AWS ECR** → Docker image registry
* **AWS ECS (Fargate)** → Serverless container orchestration
* **Terraform** → Infrastructure as Code (IaC)
* **AWS CloudWatch** → Logs and monitoring for ECS tasks

---

<pre lang="markdown"> 
## 📐 Architecture Diagram 
  ```
  flowchart TD 
  A[Developer Pushes Code] -->|GitHub Webhook| 
  B[Jenkins Pipeline] 
  B --> C[Build & Test: npm install + lint] 
  C --> D[Dockerize App] 
  D --> E[Trivy Security Scan] 
  E --> F[Push Image to AWS ECR] 
  F --> G[Terraform Apply (Main Branch)] 
  G --> H[AWS ECS Fargate Service] 
  H --> I[Deployed Node.js App] 
  H --> J[AWS CloudWatch Logs] ``` </pre>
  
## ⚡ Challenges Faced & Solutions
### Github Commits issue
* **Challenge**: Since I have many commits in my github repo, but I have built production ready structure with terraform and multibranch jenkins. If I had more time, I would have maintained the clean structure of commits


### ✅ Branch-specific Pipeline Behavior

* **Problem**: Different logic needed for `dev` vs `main` (e.g., Terraform only on `main`)
* **Solution**: Used Jenkins environment variables and `when` conditions to dynamically control pipeline logic.

---

### 🔐 ECR Authentication Issues

* **Problem**: Docker push to AWS ECR failed due to expired auth sessions.
* **Solution**: Used `aws ecr get-login-password` with `withAWS` Jenkins plugin credentials block.

---

### 🗂️ Terraform State Management

* **Problem**: Risk of branches overwriting each other's Terraform state.
* **Solution**: Remote S3 backend with DynamoDB locking. Used path-based isolation (`ecs/${branch}/terraform.tfstate`).

---

### 📄 Container Logs & Visibility

* **Problem**: Debugging ECS container issues was difficult.
* **Solution**: Configured CloudWatch log groups with retention and linked to ECS task definitions.

---

## 🚀 Possible Improvements

* **✅ Blue-Green / Canary Deployments**
  Safer zero-downtime deployment strategies.

* **✅ GitOps Workflow (ArgoCD / Flux)**
  Declarative deployments managed via Git, replacing Jenkins for delivery/deployment.

* **✅ Terraform Modules**
  Currently I have used only terraform single file for dev and main branch. But in jenkins I have seperated with the help of condition of triggers based on branch commits. We can break down infra code into reusable modules (VPC, ECS, IAM, etc.), or work with workspaces for better environment structure.

* **✅ Advanced Monitoring**
  Add CloudWatch custom metrics, alarms, Prometheus, Grafana integration.

* **✅ Secrets Management**
  Use AWS Secrets Manager or HashiCorp Vault instead of hardcoded values.

* **✅ Unit & Integration Tests**
  Enhance CI pipeline with automated test coverage reports.

---

