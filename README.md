KM Voting App - Full DevOps Project Reference
Docker, Docker Compose, Terraform, AWS networking, security groups, EC2, SSH ProxyJump, and deployment flow

1. Big Picture
The project takes the local Docker Compose voting application and deploys it as a real three-tier cloud architecture on AWS.
User
  |
  | HTTP :8080 / :8081
  v
Frontend EC2 - public subnet
  - vote app
  - result app
  - SSH bastion / jump host
  |
  | Redis traffic :6379
  v
Backend EC2 - private subnet
  - redis
  - worker
  |
  | PostgreSQL traffic :5432
  v
Database EC2 - private subnet
  - postgres

Layer	AWS resource	Runs	Access
Frontend	Public EC2	vote + result	Internet can reach ports 80, 8080, 8081. SSH only from your IP.
Backend	Private EC2	redis + worker	No public IP. SSH and Redis allowed only from frontend SG.
Database	Private EC2	postgres	No public IP. PostgreSQL allowed only from backend SG.

2. Application Data Flow
1. User opens vote page on frontend EC2.
2. Vote app sends the vote to Redis on backend EC2.
3. Worker reads votes from Redis.
4. Worker writes processed vote data into PostgreSQL on DB EC2.
5. Result app reads PostgreSQL and displays live results.

3. Docker Concepts
Concept	Meaning
Dockerfile	Recipe/instructions used to build a Docker image.
Image	Packaged app with runtime and dependencies.
Container	Running instance of an image.
Docker Compose	Runs multiple containers together from one YAML file.
Docker Hub	Registry where images are pushed and pulled.

4. vote/Dockerfile - Python Flask Service
FROM python:3.11-slim AS base

# Add curl for healthcheck/debugging
RUN apt-get update &&     apt-get install -y --no-install-recommends curl &&     rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

FROM base AS dev
RUN pip install watchdog
ENV FLASK_ENV=development
CMD ["python", "app.py"]

FROM base AS final
COPY . .
EXPOSE 80
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]

Line / block	Explanation
FROM python:3.11-slim AS base	Uses a small official Python image and names the stage base.
WORKDIR /usr/local/app	Sets the working directory inside the container. Later commands run from this folder.
COPY requirements.txt ./requirements.txt	Copies the dependency file into /usr/local/app/requirements.txt.
RUN pip install ...	Installs Python packages into the container Python environment. It reads requirements.txt from the WORKDIR.
ENV REDIS_HOST=redis	Default Redis hostname. In Docker Compose, service names become DNS names.
FROM base AS dev	Development stage. Useful for local development.
FROM base AS final	Production stage. Copies app code and runs Gunicorn.
EXPOSE 80	Documents that the container listens on port 80.

5. result/Dockerfile - Node.js Result Service
FROM node:18-slim

RUN apt-get update &&     apt-get install -y --no-install-recommends curl tini &&     rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci &&     npm cache clean --force &&     mv /usr/local/app/node_modules /node_modules

COPY . .

ENV PORT=80     PG_HOST=db     PG_PORT=5432     PG_USER=postgres     PG_PASSWORD=postgres     PG_DATABASE=postgres

EXPOSE 80

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]

Line / block	Explanation
FROM node:18-slim	Uses a slim official Node.js runtime image.
apt-get install curl tini	curl helps debugging/health checks. tini handles signals and zombie processes correctly.
npm install -g nodemon	Installs nodemon for development file watching.
COPY package*.json ./	Copies package.json and package-lock.json before app code to use Docker layer caching.
npm ci	Installs exact dependency versions from package-lock.json.
PG_HOST=db	Default Postgres hostname for local Compose. On AWS we override it with DB private IP.
ENTRYPOINT tini + CMD node	Runs the Node.js server under tini.

6. worker/Dockerfile - .NET Worker Service
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY Worker.csproj .
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish ./

ENV DB_HOST=db
ENV DB_USERNAME=postgres
ENV DB_PASSWORD=postgres
ENV DB_NAME=postgres
ENV REDIS_HOST=redis

ENTRYPOINT ["dotnet", "Worker.dll"]

Line / block	Explanation
FROM ... sdk:8.0 AS build	Build stage. Contains SDK tools needed to compile the app.
COPY Worker.csproj + dotnet restore	Restores NuGet dependencies. This is cache-friendly.
dotnet publish	Builds the production output into /app/publish.
FROM ... runtime:8.0	Final runtime stage. Smaller because it does not include the SDK.
COPY --from=build	Copies compiled output from the build stage into final runtime image.
ENV DB_HOST / REDIS_HOST	Default service names for local Compose. On AWS, override with private IPs.

Important: AS build is used later by COPY --from=build. This is why the stage has a name.
7. docker-compose.yml
services:
  vote:
    image: pokfinner/vote:latest
 #  build: ./vote
    depends_on:
      redis:
        condition: service_healthy
    ports:
      - "8080:80"
    networks:
      - back-tier

  result:
    image: pokfinner/result:latest
 #  build: ./result
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8081:80"
    networks:
      - back-tier

  worker:
 #  build: ./worker
    image: pokfinner/worker:latest
    depends_on:
      redis:
        condition: service_healthy
      db:
        condition: service_healthy
    networks:
      - back-tier

  redis:
    image: redis:alpine
    volumes:
      - "./healthchecks:/healthchecks"
    healthcheck:
      test: /healthchecks/redis.sh
      interval: "5s"
    networks:
      - back-tier

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
    volumes:
      - "db-data:/var/lib/postgresql/data"
      - "./healthchecks:/healthchecks"
    healthcheck:
      test: /healthchecks/postgres.sh
      interval: "5s"
    networks:
      - back-tier

volumes:
  db-data:

networks:
  back-tier:

Compose item	Explanation
services	Top-level section defining containers to run.
image	Uses an already-built image from Docker Hub or local cache.
build	Builds an image from a Dockerfile. Commented because this file uses pushed images.
depends_on service_healthy	Starts this service only after dependency health check passes.
ports 8080:80	Host port 8080 maps to container port 80.
networks back-tier	All containers join the same Docker network and can reach each other by service name.
volumes db-data	Persists PostgreSQL data outside the container lifecycle.

8. Terraform Files
Terraform creates the AWS infrastructure. Files are separated by purpose so the project is easier to understand.
terraform/
├── provider.tf       # Terraform + AWS provider setup
├── variables.tf      # Input variable definitions
├── terraform.tfvars  # Actual values for this project
├── networking.tf     # VPC, subnets, internet gateway, route table
├── security.tf       # Security groups/firewall rules
├── compute.tf        # EC2 instances
└── outputs.tf        # Useful IP outputs

9. provider.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

Part	Explanation
required_version	Minimum Terraform version allowed.
required_providers aws	Tells Terraform to download/use the AWS provider plugin.
provider aws region	Tells Terraform which AWS region to use.

10. variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "km-voting-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_backend_cidr" {
  description = "CIDR block for backend private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_db_cidr" {
  description = "CIDR block for db private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

variable "my_ip" {
  description = "Your public IP in CIDR format for SSH"
  type        = string
}

11. terraform.tfvars
aws_region        = "us-east-1"
availability_zone = "us-east-1a"

project_name = "km-voting-app"

ami_id   = "ami-0ec10929233384c7f"
key_name = "kondal"
my_ip    = "88.130.48.195/32"

variables.tf defines the inputs. terraform.tfvars provides the real values. The value in terraform.tfvars overrides the default.
12. networking.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_subnet" "private_backend" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_backend_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-private-backend-subnet"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_db_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-private-db-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

Resource	Explanation
aws_vpc.main	Creates the private AWS network.
aws_internet_gateway.igw	Internet door for the VPC. Required for public subnet internet access.
aws_subnet.public	Public subnet for frontend EC2. map_public_ip_on_launch=true gives public IPs.
aws_subnet.private_backend	Private subnet for backend EC2. No public IP.
aws_subnet.private_db	Private subnet for database EC2. No public IP.
aws_route_table.public	Route table with 0.0.0.0/0 through internet gateway.
aws_route_table_association.public_assoc	Attaches the public route table to the public subnet.

13. security.tf
resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "Allow HTTP and SSH to frontend instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Vote app from internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Result app from internet"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-frontend-sg"
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "${var.project_name}-backend-sg"
  description = "Allow Redis and SSH from frontend instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from frontend SG"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  ingress {
    description     = "SSH from frontend SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow PostgreSQL from backend instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from backend SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

Rule	Meaning
Frontend 80/8080/8081 from 0.0.0.0/0	Users can access the web apps.
Frontend 22 from my_ip only	Only your laptop can SSH into frontend.
Backend 6379 from frontend SG	Only frontend can reach Redis on backend.
Backend 22 from frontend SG	You can SSH to backend through frontend ProxyJump.
DB 5432 from backend SG	Only backend can connect to PostgreSQL.
No DB SSH rule	DB SSH is intentionally blocked for stricter security.

14. compute.tf
resource "aws_instance" "frontend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_instance" "backend" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_backend.id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-backend"
  }
}

resource "aws_instance" "db" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_db.id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-db"
  }
}

Instance	Subnet	Security group	Public IP	Purpose
frontend	public	frontend_sg	yes	vote + result + bastion
backend	private_backend	backend_sg	no	redis + worker
db	private_db	db_sg	no	postgres

15. outputs.tf
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  value = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  value = aws_instance.backend.private_ip
}

output "db_private_ip" {
  value = aws_instance.db.private_ip
}

Outputs are printed after terraform apply. They are used for SSH config and Ansible inventory.
16. Terraform Commands and Meaning
terraform init       # downloads provider plugins
terraform fmt        # formats Terraform files
terraform validate   # checks syntax and references
terraform plan       # previews what Terraform will create/change/destroy
terraform apply      # creates/updates real AWS resources
terraform output     # prints output values like public/private IPs
terraform state list # shows resources currently managed by Terraform
terraform destroy    # deletes all resources managed by this Terraform project

17. SSH and ProxyJump
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host frontend-instance-1
  HostName 44.199.233.121
  User ubuntu
  IdentityFile ~/project1_ironhack/terraform/kondal.pem

Host backend-instance-1
  HostName 10.0.2.132
  User ubuntu
  IdentityFile ~/project1_ironhack/terraform/kondal.pem
  ProxyJump frontend-instance-1

Host db-instance-1
  HostName 10.0.3.118
  User ubuntu
  IdentityFile ~/project1_ironhack/terraform/kondal.pem
  ProxyJump frontend-instance-1

Line	Explanation
Host frontend-instance-1	Shortcut name for the public frontend EC2.
HostName 44.199.233.121	Public IP of frontend EC2. This changes after destroy/apply.
IdentityFile ...kondal.pem	Private SSH key used for login.
ProxyJump frontend-instance-1	SSH first connects to frontend, then jumps to private backend.
db-instance-1	Configured, but direct SSH fails unless DB SG allows SSH from frontend.

chmod 400 ~/project1_ironhack/terraform/kondal.pem
chmod 600 ~/.ssh/config

ssh frontend-instance-1
ssh backend-instance-1

# DB SSH is intentionally blocked in the stricter setup:
ssh db-instance-1

18. Next Step - Ansible Deployment
Ansible will automate Docker installation and container deployment on EC2. The final target is:
Server	Containers	Notes
frontend	vote, result	Expose vote on 8080 and result on 8081.
backend	redis, worker	Redis listens on 6379. Worker connects to Redis and DB.
db	postgres	Postgres listens on 5432. Data should use a Docker volume.

19. Manual docker run Logic for Deployment
These commands show the logic that Ansible will later automate.
# On DB EC2
sudo docker run -d --name postgres   -e POSTGRES_USER=postgres   -e POSTGRES_PASSWORD=postgres   -v pgdata:/var/lib/postgresql/data   -p 5432:5432   postgres:15-alpine

# On Backend EC2
sudo docker run -d --name redis   -p 6379:6379   redis:alpine

sudo docker run -d --name worker   -e REDIS_HOST=10.0.2.132   -e DB_HOST=10.0.3.118   -e DB_USERNAME=postgres   -e DB_PASSWORD=postgres   -e DB_NAME=postgres   pokfinner/worker:latest

# On Frontend EC2
sudo docker run -d --name vote   -p 8080:80   -e REDIS_HOST=10.0.2.132   pokfinner/vote:latest

sudo docker run -d --name result   -p 8081:80   -e PG_HOST=10.0.3.118   -e PG_PORT=5432   -e PG_USER=postgres   -e PG_PASSWORD=postgres   -e PG_DATABASE=postgres   pokfinner/result:latest

Important: if containers run on different EC2 instances, Docker service names like redis and db no longer work. Use private IPs or internal DNS instead.
20. Example Ansible Inventory and Docker Install Playbook
# ansible/inventory.ini
[frontend]
frontend-instance-1

[backend]
backend-instance-1

[db]
# DB is currently not SSH-accessible in strict setup.
# If you want Ansible to manage DB directly, allow SSH from frontend SG to DB SG temporarily.
db-instance-1

# ansible/install-docker.yml
- name: Install Docker on Ubuntu servers
  hosts: all
  become: yes
  tasks:
    - name: Update apt package index
      ansible.builtin.apt:
        update_cache: yes

    - name: Install Docker
      ansible.builtin.package:
        name: docker.io
        state: present

    - name: Start and enable Docker
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes

    - name: Add ubuntu user to docker group
      ansible.builtin.user:
        name: ubuntu
        groups: docker
        append: yes

21. Final Testing
# Browser tests
http://<frontend-public-ip>:8080   # vote app
http://<frontend-public-ip>:8081   # result app

# Container status
sudo docker ps

# Logs
sudo docker logs vote
sudo docker logs result
sudo docker logs worker
sudo docker logs redis
sudo docker logs postgres

# Backend to DB connectivity test
nc -zv 10.0.3.118 5432

22. Presentation Summary
•	Dockerfiles package each microservice into a reusable image.
•	Docker Compose validates the full stack locally before cloud deployment.
•	Terraform provisions VPC, subnets, internet gateway, route table, security groups, and EC2 instances.
•	Frontend is public; backend and DB remain private.
•	Security groups implement tier-based access control.
•	ProxyJump lets us reach private backend through the public frontend bastion.
•	Ansible automates Docker installation and container deployment.
