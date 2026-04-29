# 🚀 Multi-Tier Voting App on AWS (DevOps Project)

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![Docker](https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker)
![Ansible](https://img.shields.io/badge/Ansible-Automation-red?logo=ansible)
![HTTPS](https://img.shields.io/badge/HTTPS-Secured-green)

---

## 📌 Overview

A production-style multi-tier application deployed on AWS using:

- Terraform (Infrastructure as Code)
- Docker (Containerization)
- Ansible (Automation)
- AWS ALB, Route53, HTTPS

---

## 🎥 Live Demo

👉 https://kondal.online  
👉 https://kondal.online/result  

---

## 🏗️ Architecture

User → Route53 → ALB → Frontend → Backend → Database

---

## ⚙️ Tech Stack

Terraform | AWS | Docker | Ansible | PostgreSQL | Redis

---

## 🧪 Run Locally

```bash
docker compose up
```

---

## ☁️ Deploy to AWS

```bash
cd terraform
terraform init
terraform apply
```

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml
```

---

## 🔐 Networking Design

- Public subnet → ALB + Frontend  
- Private subnet → Backend + DB  
- IGW + NAT Gateway  

---

## ⚠️ Challenges & Solutions

- Private EC2 access → Bastion host  
- NAT issue → Fixed route tables  
- HTTPS issue → Opened port 443  
- Git push error → Used .gitignore  

---

## 👨‍💻 Author

Kondal Moganti
