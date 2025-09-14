
## 🛠️ Troubleshooting

Here are some common issues you might face and how to fix them (Myself faced them):

### 1️⃣ Docker Login to ECR Fails
**Error:**
```
Get "https://<account_id>.dkr.ecr.ap-south-1.amazonaws.com/v2/": no such host
```
✅ Fix:
- Ensure you have internet/DNS access.
- Run:
  ```bash
  aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.ap-south-1.amazonaws.com
  ```
- Check your AWS credentials with `aws configure list`.

---

### 2️⃣ Terraform Apply Fails Due to IAM Role
**Error:**
```
AccessDenied: User is not authorized to perform: ecs:CreateService
```
✅ Fix:
- Attach `AmazonECSTaskExecutionRolePolicy` to the ECS execution role.
- Ensure Jenkins AWS credentials have `AdministratorAccess` or required ECS/ECR/ALB permissions.

---

### 3️⃣ ECS Task Stuck in `PENDING`
**Possible Causes:**
- Wrong image URL in task definition.
- ECR image not found.
- Security group or subnet misconfiguration.

✅ Fix:
- Verify `image` field in `task_definition.json`:
  ```
  <account_id>.dkr.ecr.ap-south-1.amazonaws.com/logo-server-repo:latest
  ```
- Ensure ECS task has internet access (via NAT Gateway or public subnet).

---

### 4️⃣ ALB Shows 502 Bad Gateway
✅ Fix:
- Check if ECS task is healthy.
- Confirm health check path in ALB matches your Node.js app (e.g., `/health` or `/`).
- Verify the app listens on the same port as defined in `task definition` and `Dockerfile`.

---

### 5️⃣ Jenkins Pipeline Fails on `terraform init`
✅ Fix:
- Ensure Terraform is installed on Jenkins node.
- Verify AWS credentials are correctly added in Jenkins (Manage Jenkins → Credentials).
- Check workspace permissions.

---

### 6️⃣ Jenkins Doesn’t Trigger on PR Merge
✅ Fix:
- Confirm GitHub Webhook is set under **Repo → Settings → Webhooks**.
- Webhook should point to:
  ```
  http://<jenkins-url>/github-webhook/
  ```
- Ensure Jenkins Multibranch Pipeline scans the repo.

---

## 🎯 Final Notes
- Always test infra changes on **dev branch** first.
- Keep your Terraform state in a **remote backend (S3 + DynamoDB)** for production.
- Monitor ECS service in **CloudWatch** for logs and scaling.
