# 🚀 Multi-Tier Voting App on AWS

A production-style DevOps project that deploys a containerized voting application on AWS using Terraform, Docker, Ansible, ALB, Route53, and HTTPS.

---

## 🏗️ Architecture Diagram

<img width="1536" height="1024" alt="architecture diagram" src="https://github.com/user-attachments/assets/2d220aa2-2b43-4a95-a224-70673614365e" />


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

- Docker & Docker Compose installed  
- Terraform installed  
- AWS CLI configured (`aws configure`)  
- Ansible installed  
- SSH key (.pem file)  

---

## 🖥️ How to Run Locally

```bash
docker compose up
```

Access:
- http://localhost:8080  
- http://localhost:8081  

---

## ☁️ How to Deploy to AWS

### Step 1 — Clone Repository

```bash
git clone https://github.com/kondalmoganti/ironhack_project1.git
cd ironhack_project1
```

### Step 2 — Terraform

```bash
cd terraform
terraform init
terraform apply
```

### Step 3 — SSH Access

```bash
ssh -i kondal.pem ubuntu@<frontend-public-ip>
```

### Step 4 — Ansible Deployment

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

### Step 5 — Access

https://kondal.online  
https://kondal.online/result  

---

## 🔑 Environment Variables

| Variable | Description |
|--------|------------|
| REDIS_HOST | Redis IP |
| DB_HOST | Database IP |
| POSTGRES_HOST | DB host |
| PG_HOST | PostgreSQL host |
| PG_PORT | 5432 |
| PG_USER | postgres |
| PG_PASSWORD | postgres |
| PG_DATABASE | postgres |

---

## ⚠️ Known Issues / Limitations

- ACM created manually  
- No auto-scaling  
- Uses EC2 instead of RDS  
- Bastion required for private access  
- No CI/CD pipeline  

---

## 👨‍💻 Author

Kondal Moganti  
GitHub: https://github.com/kondalmoganti  
LinkedIn: https://www.linkedin.com/in/YOUR-LINK-HERE  

---

## ⭐ Live Demo

https://kondal.online  
https://kondal.online/result  
