# DevOps – demo Server

A simple Node.js + Express.js application that serves the `logoswayatt.png` image and demonstrates a complete CI/CD pipeline using Jenkins, Docker, Terraform, and AWS.

---

## 📌 Objective
Set up a CI/CD pipeline for a sample application using **AWS**, **Jenkins**, and **GitHub**.  
The pipeline showcases automation, scalability, and DevOps best practices.

---

## 🏗️ Architecture Diagram

**Flow:**  
Developer → GitHub (main/dev) → Jenkins (Webhook Trigger) → Docker Build & Push → AWS ECS Deployment → User accesses `http://13.235.86.93:3000`

---

## 🗂 Project Structure
devops-task/
├── Terraform/
│ ├── main.tf
│ ├── outputs.tf
│ ├── provider.tf
│ ├── variables.tf
├── Deployment-proof
│ ├── LIVE
│ ├── DOCKER
│ ├── AWS
│ ├── JENKINS
│ ├── LOCAL
├── .gitignore
├── app.js # Express server
├── Dockerfile
├── Jenkinsfile
├── logoswayatt.png # Served image
├── package.json
├── package-lock.json
└── README.md

yaml
Copy code

---

## 🚀 Setup & Deployment

### 1️⃣ Prerequisites
- Node.js ≥ 12  
- npm  
- Docker & DockerHub account  
- AWS account with ECS and IAM roles  
- Jenkins server

### 2️⃣ Local Run
### Bash
{npm install
npm start
Access at: http://localhost:3000}

### ⚙️ CI/CD Pipeline Flow
Source Control

GitHub repository with branching strategy: main & dev.(deployment on main)

Webhook triggers Jenkins on every push.

Build Stage

Install Node dependencies.

Run tests (if added in the future).

Dockerize

Build Docker image using the provided Dockerfile.

Push to Registry

Push the image to DockerHub or AWS ECR.

Deploy

Terraform provisions AWS ECS cluster & services.

Jenkins deploys the latest image automatically.

Monitoring & Logging

CloudWatch collects logs and basic metrics for container performance.

### 🌐 Deployed Application
Public URL: http://13.235.86.93:3000

### 🛠 Tools & Services Used
Node.js & Express.js – Web application framework

Docker – Containerization

Jenkins – CI/CD automation

Terraform – Infrastructure as Code

AWS ECS & CloudWatch – Deployment & monitoring

GitHub – Source control

### 🧩 Challenges & Solutions
Jenkins on t2.micro:
Running Jenkins on a free-tier t2.micro EC2 instance caused frequent service stops because of limited CPU and memory.
Solution: Optimized Jenkins by reducing build concurrency and cleaning up old builds. For production, upgrading to at least t3.small is recommended.

AWS Billing Concerns:
Continuous deployment and ECS tasks increased monthly AWS charges.
Solution: Configured automatic cleanup of unused resources, enabled billing alarms, and stopped non-essential services when idle.

These experiences highlight the importance of right-sizing infrastructure and actively monitoring costs.

### 🔮 Possible Improvements
Add automated tests to the pipeline.

Use a multi-stage Docker build to reduce image size.

Enable HTTPS with a load balancer and SSL certificate.

Set up Terraform remote backend (e.g., S3 + DynamoDB) for safer state management.

### 🖼️ Application Overview
This lightweight Express.js server listens on port 3000 and serves a single image (logoswayatt.png) at the root endpoint /.

### Endpoint:
GET / → Returns the Swayatt logo image.
Server running on http://0.0.0.0:3000
Access the live application: http://13.235.86.93:3000
