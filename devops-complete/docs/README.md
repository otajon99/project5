# Complete DevOps Lab Project Guide

## Project Overview

This project implements a complete DevOps infrastructure lab with:
- **On-Premise Servers**: 10 VMs via VirtualBox (Ansible managed)
- **AWS Cloud Infrastructure**: Terraform-deployed VPC, ALB, ASG, RDS
- **CI/CD Pipeline**: GitHub Actions or Jenkins
- **Monitoring**: Nagios
- **Containerization**: Docker
- **Orchestration**: Kubernetes (Minikube)

---

## Table of Contents

1. [Server Specifications](#server-specifications)
2. [Ansible Configuration](#ansible-configuration)
3. [AWS Terraform Infrastructure](#aws-terraform-infrastructure)
4. [CI/CD Pipeline](# cicd-pipeline)
5. [Running the Project](#running-the-project)
6. [Verification Steps](#verification-steps)

---

## Server Specifications

### On-Premise VMs (VirtualBox)

| Server | IP Address | CPU | RAM | Disk | Purpose |
|--------|------------|-----|-----|------|---------|
| prdx-dns101 | 10.31.3.11 | 1 | 1G | 5G | DNS Server |
| prdx-db101 | 10.31.3.12 | 1 | 1G | 5G | MariaDB |
| prdx-webserver101 | 10.31.3.21 | 1 | 1G | 5G | Web Server 1 |
| prdx-webserver102 | 10.31.3.22 | 1 | 1G | 5G | Web Server 2 |
| prdx-webserver103 | 10.31.3.23 | 1 | 1G | 5G | Web Server 3 |
| prdx-haproxy101 | 10.31.3.30 | 1 | 1G | 5G | Load Balancer |
| prdx-nagios101 | 10.31.3.40 | 1 | 1G | 5G | Monitoring |
| prdx-ansible101 | 10.31.3.10 | 1 | 1G | 9G | Ansible Controller |
| prdx-dprimary101 | 10.31.3.50 | 4 | 4G | 15G | Docker |
| prdx-kube101 | 10.31.3.60 | 1 | 3G | 5G | Kubernetes |

---

## Ansible Configuration

### Quick Start

```bash
# SSH to Ansible server
ssh ansible@10.31.3.10

# Test connectivity
ansible all -i inventory/hosts -m ping

# Run all playbooks
ansible-playbook -i inventory/hosts playbooks/site.yml

# Or run individual playbooks
ansible-playbook -i inventory/hosts playbooks/01-base-security.yml
ansible-playbook -i inventory/hosts playbooks/02-dns-server.yml
ansible-playbook -i inventory/hosts playbooks/03-webservers.yml
ansible-playbook -i inventory/hosts playbooks/04-loadbalancer.yml
ansible-playbook -i inventory/hosts playbooks/05-database.yml
ansible-playbook -i inventory/hosts playbooks/06-nrpe-client.yml
ansible-playbook -i inventory/hosts playbooks/07-nagios-server.yml
ansible-playbook -i inventory/hosts playbooks/08-docker.yml
ansible-playbook -i inventory/hosts playbooks/09-kubernetes.yml
```

### Playbooks Overview

| Playbook | Description |
|----------|-------------|
| 01-base-security.yml | SELinux disabled, Firewall enabled, Common packages |
| 02-dns-server.yml | BIND DNS server with forward/reverse zones |
| 03-webservers.yml | Apache with 3 web servers |
| 04-loadbalancer.yml | HAProxy with round-robin load balancing |
| 05-database.yml | MariaDB with sample employee database |
| 06-nrpe-client.yml | NRPE for Nagios monitoring |
| 07-nagios-server.yml | Nagios Core with host/service monitoring |
| 08-docker.yml | Docker with web application |
| 09-kubernetes.yml | Minikube with dashboard & ingress |

---

## AWS Terraform Infrastructure

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    Internet Gateway                          │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                    Public Subnet 1 (AZ-a)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  App1 EC2   │  │  App1 EC2   │  │  App1 EC2   │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
┌─────────▼────────────────▼────────────────▼─────────────────┐
│                   Application Load Balancer                  │
│              /path1/* → App1 TG                            │
│              /path2/* → App2 TG                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   Private Subnet 1 (AZ-a)                   │
│  ┌─────────────┐                                            │
│  │    RDS     │                                            │
│  └─────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

### Terraform Commands

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Create execution plan
terraform plan -out=tfplan

# Apply changes
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy -auto-approve
```

### AWS Resources Created

| Resource | Description |
|----------|-------------|
| VPC | 10.0.0.0/16 with public/private subnets |
| Internet Gateway | For public subnet internet access |
| NAT Gateway | For private subnet internet access |
| Application Load Balancer | With path-based routing |
| Target Groups | App1 and App2 target groups |
| Auto Scaling Groups | For both App1 and App2 |
| Launch Templates | With user data for web servers |
| CloudWatch Alarms | CPU-based scaling policies |
| RDS | MySQL database instance |
| S3 Bucket | For Terraform state |

---

## CI/CD Pipeline

### GitHub Actions

1. **Workflow triggers on**: Push to main, Pull requests
2. **Stages**:
   - Checkout code
   - Configure AWS credentials
   - Terraform: Init → Validate → Plan → Apply
   - Ansible: Run all playbooks
   - Docker: Build and push image
   - Security: Trivy vulnerability scan

### Jenkins Pipeline

1. **Stages**:
   - Checkout SCM
   - Terraform Init/Validate/Plan/Apply
   - Ansible Playbook execution
   - Docker build
   - Security scan
   - AWS deployment

---

## Running the Project

### Step 1: Set Up VirtualBox VMs

1. Install VirtualBox on your machine
2. Create 10 VMs with Rocky Linux 9
3. Configure network adapters (Host-only or Bridged)
4. Set static IP addresses as specified

### Step 2: Configure Ansible Server

```bash
# On prdx-ansible101 (10.31.3.10)
ssh root@10.31.3.10

# Install Ansible
dnf install -y epel-release
dnf install -y ansible

# Generate SSH key
ssh-keygen -t rsa -b 4096

# Copy SSH key to all servers
for ip in 10 11 12 21 22 23 30 40 50 60; do
  ssh-copy-id root@10.31.3.$ip
done
```

### Step 3: Run Ansible Playbooks

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

### Step 4: Deploy AWS Infrastructure

```bash
# Configure AWS credentials
aws configure

# Deploy with Terraform
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 5: Set Up CI/CD

**Option A: GitHub Actions**
1. Push code to GitHub
2. Add secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
3. Workflow runs automatically

**Option B: Jenkins**
1. Install Jenkins on Rocky Linux 9
2. Create pipeline job
3. Link Jenkinsfile
4. Run pipeline

---

## Verification Steps

### On-Premise Verification

```bash
# Test Ansible connectivity
ansible all -m ping

# Check DNS resolution
ansible all -m shell -a "cat /etc/resolv.conf"

# Verify Load Balancer
curl http://10.31.3.30

# Check Database
ssh ansible@10.31.3.12
mysql -u devops_user -p -e "USE devops_lab; SELECT * FROM employees;"

# Access Nagios
# URL: http://10.31.3.40/nagios
# User: nagiosadmin
# Pass: nagios

# Check Docker
curl http://10.31.3.50:8080

# Check Kubernetes
ssh ansible@10.31.3.60
minikube status
minikube dashboard --url
```

### AWS Verification

```bash
# Check VPC
aws ec2 describe-vpcs --region us-east-1

# Check ALB
aws elbv2 describe-load-balancers --region us-east-1

# Check ASG
aws autoscaling describe-auto-scaling-groups --region us-east-1

# Test ALB
curl http://<alb-dns-name>/path1/
curl http://<alb-dns-name>/path2/

# Check RDS
aws rds describe-db-instances --region us-east-1
```

---

## URLs Summary

| Service | URL | Credentials |
|---------|-----|-------------|
| Load Balancer | http://10.31.3.30 | - |
| HAProxy Stats | http://10.31.3.30:8888/stats | admin/password |
| Nagios | http://10.31.3.40/nagios | nagiosadmin/nagios |
| Docker App | http://10.31.3.50:8080 | - |
| Kubernetes Dashboard | minikube dashboard --url | - |
| AWS ALB | Check Terraform output | - |

---

## Project Structure

```
devops-complete/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts
│   └── playbooks/
│       ├── 01-base-security.yml
│       ├── 02-dns-server.yml
│       ├── 03-webservers.yml
│       ├── 04-loadbalancer.yml
│       ├── 05-database.yml
│       ├── 06-nrpe-client.yml
│       ├── 07-nagios-server.yml
│       ├── 08-docker.yml
│       └── 09-kubernetes.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
│       ├── vpc/
│       ├── ec2/
│       ├── alb/
│       ├── asg/
│       └── rds/
├── github-actions/
│   └── pipeline.yml
├── jenkins/
│   └── Jenkinsfile
└── docs/
    └── README.md
```

---

## Troubleshooting

### Ansible Issues

```bash
# Reset connection
ansible all -i inventory/hosts -m ping

# Debug SSH
ansible all -i inventory/hosts -m ping -vvv

# Check SSH key
ssh -v ansible@10.31.3.X
```

### Terraform Issues

```bash
# Refresh state
terraform refresh

# Check state
terraform show

# Untaint resources
terraform untaint <resource>
```

### AWS Issues

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check VPC
aws ec2 describe-vpcs

# Check logs
aws logs tail /aws/ec2/instance-id
```

---

**🎉 Congratulations! Your Complete DevOps Lab is ready!**
