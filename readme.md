# 🚀 Multi-Tier Voting App Deployment (AWS DevOps Project)

## 📌 Overview

<img width="1480" height="1109" alt="image" src="https://github.com/user-attachments/assets/c188e712-db89-4071-a3c0-6c2991770097" />

This project demonstrates a production-style DevOps setup using Terraform, Docker, Ansible, AWS ALB, Route53, and HTTPS.

---

## 🏗️ Architecture

User → ALB → Frontend EC2 → Backend EC2 → DB EC2

- Frontend: Vote & Result apps
- Backend: Redis + Worker
- Database: PostgreSQL

---

## ⚙️ Technologies Used

- Terraform (Infrastructure as Code)
- AWS (VPC, EC2, ALB, Route53, ACM)
- Docker (Containerization)
- Ansible (Automation)
- Linux / WSL

---

## 🔁 Data Flow

1. User submits vote  
2. Vote stored in Redis  
3. Worker processes vote  
4. Data stored in PostgreSQL  
5. Result app displays results  

---

## 🔐 Features

- Private & Public subnets
- NAT Gateway for private access
- Bastion host SSH access
- Load Balancer (ALB)
- Custom domain with HTTPS (SSL)
- Automated deployment with Ansible

---

## 🌐 Live Demo

- Vote: https://kondal.online  
- Result: https://kondal.online/result  

---

## 🚀 Deployment

### Terraform
```bash
terraform init
terraform apply
