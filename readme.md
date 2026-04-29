# 🚀 Multi-Tier Voting App on AWS

A production-style DevOps project deploying a containerized voting application on AWS using Terraform, Docker, Ansible, ALB, Route53, and HTTPS.

---

## 🏗️ Architecture

![Architecture Diagram](./assets/architecture.png)

### Flow:
User → Route53 → ALB → Frontend → Backend → Database

- Frontend: Vote (Flask) & Result (Node.js)
- Backend: Redis + Worker (.NET)
- Database: PostgreSQL
- Networking: VPC, Public/Private Subnets, NAT Gateway, Internet Gateway

---

## 🛠️ Tech Stack

![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Docker](https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker)
![Ansible](https://img.shields.io/badge/Ansible-Automation-red?logo=ansible)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)
![Redis](https://img.shields.io/badge/Redis-Cache-red?logo=redis)

---

## ⚙️ Prerequisites

Make sure you have:

- Docker & Docker Compose
- AWS CLI configured
- Terraform installed
- Ansible installed
- SSH key (.pem file)

---

## 🖥️ Run Locally

```bash
docker compose up

Access:

Vote: http://localhost:8080
Result: http://localhost:8081
☁️ Deploy to AWS
Step 1 — Clone repo
git clone https://github.com/kondalmoganti/ironhack_project1.git
cd ironhack_project1
Step 2 — Terraform (Infrastructure)
cd terraform
terraform init
terraform plan
terraform apply

This creates:

VPC + Subnets
Internet Gateway + NAT Gateway
EC2 Instances (Frontend, Backend, DB)
Security Groups
Application Load Balancer
Route53 DNS + HTTPS
Step 3 — SSH Access
scp -i kondal.pem kondal.pem ubuntu@<frontend-public-ip>:~/

ssh -i kondal.pem ubuntu@<frontend-public-ip>
ssh -i kondal.pem ubuntu@<backend-private-ip>
Step 4 — Ansible Deployment
cd ../ansible
ansible-playbook -i inventory.ini deploy.yml

This will:

Install Docker
Pull images from Docker Hub
Run containers
Step 5 — Access Application
https://kondal.online
https://kondal.online/result
🔑 Environment Variables
Variable	Description
REDIS_HOST	Backend Redis IP
DB_HOST	PostgreSQL host
POSTGRES_HOST	Database host
PG_HOST	Database connection host
PG_PORT	Database port (5432)
PG_USER	PostgreSQL username
PG_PASSWORD	PostgreSQL password
PG_DATABASE	Database name
⚠️ Known Issues / Limitations
Manual ACM certificate creation (not fully automated)
No auto-scaling (single EC2 per tier)
Uses EC2 instead of managed RDS (not production-grade DB)
Bastion setup required for private access
No CI/CD pipeline yet
🧠 Key Learnings
Infrastructure as Code with Terraform
AWS networking (VPC, NAT, IGW)
Container orchestration with Docker
Automation using Ansible
Debugging distributed systems
👨‍💻 Author

Kondal Moganti

🔗 GitHub: https://github.com/kondalmoganti

🔗 LinkedIn: https://www.linkedin.com/in/YOUR-LINK-HERE

⭐ Live Demo

👉 https://kondal.online

👉 https://kondal.online/result


---

# 🚀 Next Step

👉 Create a folder:

```bash
mkdir assets

👉 Save your architecture image as:

assets/architecture.png
