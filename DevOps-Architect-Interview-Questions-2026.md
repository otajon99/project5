# DevOps Architect Interview Questions & Answers 2026

## Table of Contents
1. [CI/CD & Build Pipelines](#1-cicd--build-pipelines)
2. [Docker & Containerization](#2-docker--containerization)
3. [Kubernetes & Orchestration](#3-kubernetes--orchestration)
4. [AWS Cloud Services](#4-aws-cloud-services)
5. [Terraform & Infrastructure as Code](#5-terraform--infrastructure-as-code)
6. [Ansible & Configuration Management](#6-ansible--configuration-management)
7. [Monitoring & Logging](#7-monitoring--logging)
8. [System Design & Architecture](#8-system-design--architecture)
9. [Security & Compliance](#9-security--compliance)
10. [Linux & Networking](#10-linux--networking)

---

## 1. CI/CD & Build Pipelines

### Q1: What is CI/CD and why is it important?
**Answer:** CI/CD stands for Continuous Integration and Continuous Deployment/Delivery. It automates the process of integrating code changes, testing, and deploying applications.

**Benefits:**
- Faster time-to-market
- Early bug detection
- Reduced manual errors
- Consistent deployments
- Improved collaboration

### Q2: What are the differences between Continuous Delivery vs Continuous Deployment?
**Answer:**
- **Continuous Delivery:** Code changes are automatically prepared for release to production but require manual approval
- **Continuous Deployment:** Every change that passes all stages is automatically deployed to production without manual intervention

### Q3: Explain the CI/CD pipeline stages.
**Answer:**
1. **Source/Checkout** - Code checkout from repository
2. **Build** - Compile code, compile assets
3. **Test** - Unit, integration, E2E tests
4. **Security Scan** - SAST, DAST, dependency checks
5. **Artifact Storage** - Store build artifacts
6. **Deploy to Staging** - Deploy to staging environment
7. **Deploy to Production** - Blue/Green or Canary deployment
8. **Verification** - Post-deployment smoke tests

### Q4: What is GitOps?
**Answer:** GitOps is a way of implementing Continuous Deployment for cloud native applications. It uses Git as a single source of truth for declarative infrastructure and applications.

**Benefits:**
- Improved security (audit trail in Git)
- Enhanced reliability
- Faster deployments
- Better collaboration

### Q5: What is a canary deployment?
**Answer:** A deployment strategy where a small percentage of traffic is routed to the new version while most traffic goes to the stable version. This allows testing in production with minimal risk.

```yaml
# Example: Kubernetes Canary Deployment
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp-stable
  labels:
    app: myapp
    version: stable
spec:
  containers:
  - image: myapp:v1
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp-canary
  labels:
    app: myapp
    version: canary
spec:
  replicas: 1
  containers:
  - image: myapp:v2
```

---

## 2. Docker & Containerization

### Q6: What is Docker and how does it differ from VMs?
**Answer:** Docker is a containerization platform that packages applications and their dependencies into containers.

**Differences from VMs:**
| Aspect | Docker Containers | Virtual Machines |
|--------|------------------|-----------------|
| Size | MBs | GBs |
| Startup | Seconds | Minutes |
| Isolation | Process-level | Full OS |
| Performance | Near native | Overhead |
| Portability | Highly portable | Less portable |

### Q7: Explain Docker architecture.
**Answer:**
- **Docker Daemon:** Background service managing containers
- **Docker Client:** CLI tool to interact with daemon
- **Docker Registry:** Stores Docker images (Docker Hub, ECR, GCR)
- **Docker Objects:** Images, Containers, Volumes, Networks

### Q8: What is a Dockerfile and explain key instructions?
**Answer:** A Dockerfile is a script containing instructions to build a Docker image.

```dockerfile
FROM ubuntu:22.04          # Base image
LABEL maintainer="email"    # Metadata
RUN apt-get update && \     # Commands during build
    apt-get install -y nginx
COPY ./app /var/www/html   # Copy files
WORKDIR /var/www/html      # Set working directory
ENV APP_ENV=production     # Environment variables
EXPOSE 80                  # Expose port
USER nobody                # Set user
CMD ["nginx", "-g", "daemon off;"]  # Default command
```

### Q9: Docker networking modes
**Answer:**
- **Bridge:** Default network, containers on same host communicate
- **Host:** Container shares host's network stack
- **Overlay:** Multi-host container communication (Swarm)
- **None:** No networking
- **Macvlan:** Containers get MAC addresses

### Q10: How do you reduce Docker image size?
**Answer:**
1. Use minimal base images (alpine, scratch)
2. Chain RUN commands
3. Copy only necessary files
4. Use multi-stage builds
5. Clean up in same layer

```dockerfile
# Multi-stage build example
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

FROM alpine:latest
COPY --from=builder /app/myapp /usr/local/bin/
CMD ["myapp"]
```

---

## 3. Kubernetes & Orchestration

### Q11: What is Kubernetes and its key components?
**Answer:** Kubernetes is a container orchestration platform for automating deployment, scaling, and management of containerized applications.

**Control Plane Components:**
- kube-apiserver
- etcd
- kube-scheduler
- kube-controller-manager
- cloud-controller-manager

**Node Components:**
- kubelet
- kube-proxy
- container runtime (containerd)

### Q12: Explain Kubernetes architecture.
**Answer:**
```
┌─────────────────────────────────────────────────┐
│                  Control Plane                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│  │ API     │ │ Scheduler│ │ Controller Mgr  │ │
│  │ Server  │ │         │ │                 │ │
│  └────┬────┘ └────┬────┘ └────────┬────────┘ │
│       │            │                │            │
│       └────────────┴────────────────┘         │
│                    │                            │
│              ┌─────┴─────┐                     │
│              │   etcd   │                     │
│              └───────────┘                     │
└─────────────────────┬─────────────────────────┘
                      │
┌─────────────────────┴─────────────────────────┐
│                    Nodes                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────────┐ │
│  │ kubelet │  │kube-proxy│  │containerd   │ │
│  └────┬────┘  └────┬────┘  └──────┬──────┘ │
│       │             │               │          │
│       └─────────────┴───────────────┘          │
│              ┌────────┐                       │
│              │  Pods  │                       │
│              │ ┌────┐│                       │
│              │ │nginx││                       │
│              │ └────┘│                       │
│              └────────┘                       │
└───────────────────────────────────────────────┘
```

### Q13: What is a Pod, Deployment, and Service?
**Answer:**
- **Pod:** Smallest deployable unit, contains one or more containers
- **Deployment:** Manages Pod replicas, handles updates and rollbacks
- **Service:** Stable network endpoint to access Pods

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v1
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

### Q14: What are the different Service types?
**Answer:**
1. **ClusterIP:** Internal cluster IP (default)
2. **NodePort:** Exposes on each node's IP
3. **LoadBalancer:** External load balancer
4. **ExternalName:** Maps to external DNS name

### Q15: Explain Kubernetes ConfigMap and Secret.
**Answer:**
- **ConfigMap:** Non-sensitive configuration data
- **Secret:** Sensitive data (base64 encoded by default)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "db.example.com"
  LOG_LEVEL: "info"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DB_PASSWORD: "supersecret"
  API_KEY: "api-key-here"
```

### Q16: How do you handle persistent storage in Kubernetes?
**Answer:** Using PersistentVolume (PV) and PersistentVolumeClaim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-volume
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

### Q17: What is Ingress and how does it work?
**Answer:** Ingress manages external HTTP/HTTPS access to services in the cluster.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

### Q18: Explain Helm and its benefits.
**Answer:** Helm is a package manager for Kubernetes that packages YAML files into Charts.

```bash
# Install chart
helm install myapp ./myapp-chart

# Update chart
helm upgrade myapp ./myapp-chart

# Rollback
helm rollback myapp 1

# List releases
helm list
```

### Q19: How do you secure Kubernetes?
**Answer:**
1. RBAC (Role-Based Access Control)
2. Network Policies
3. Pod Security Policies/Standards
4. Secrets encryption
5. Container image scanning
6. Security contexts
7. Resource limits/quotas
8. Regular security updates

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### Q20: What is Horizontal Pod Autoscaler (HPA)?
**Answer:** Automatically scales the number of pods based on CPU/memory utilization.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

## 4. AWS Cloud Services

### Q21: What are the key AWS services for DevOps?
**Answer:**
- **Compute:** EC2, ECS, EKS, Lambda, Fargate
- **Networking:** VPC, Route 53, ALB, NLB, CloudFront
- **Storage:** S3, EBS, EFS, FSx
- **Database:** RDS, DynamoDB, ElastiCache
- **CI/CD:** CodePipeline, CodeBuild, CodeDeploy
- **Monitoring:** CloudWatch, X-Ray, CloudTrail

### Q22: Explain AWS VPC components.
**Answer:**
- **VPC:** Virtual Private Cloud (isolated network)
- **Subnets:** Public (has IGW route) / Private (no IGW route)
- **Route Tables:** Define traffic routing
- **Internet Gateway:** Connects VPC to internet
- **NAT Gateway:** Allows private subnet outbound internet
- **Security Groups:** Stateful firewall at instance level
- **NACLs:** Stateless firewall at subnet level

### Q23: What is an Auto Scaling Group (ASG)?
**Answer:** Automatically adjusts compute capacity based on demand.

```yaml
# AWS CLI example
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name my-asg \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 4 \
  --vpc-zone-identifier subnet-12345678 \
  --launch-template-name my-launch-template
```

### Q24: S3 vs EBS vs EFS - When to use each?
**Answer:**
- **S3:** Object storage, static websites, backups, data lake
- **EBS:** Block storage for single EC2 instance
- **EFS:** Network file system for multiple EC2 instances

### Q25: What is AWS Fargate?
**Answer:** Serverless compute engine for containers that eliminates the need to manage servers or clusters.

### Q26: Explain AWS Lambda cold starts and optimization.
**Answer:** Cold start is the delay when Lambda function is invoked after being idle.

**Optimization strategies:**
1. Increase memory (faster CPU)
2. Use Provisioned Concurrency
3. Optimize function package size
4. Use AWS SnapStart (Java)
5. Keep connections warm

---

## 5. Terraform & Infrastructure as Code

### Q27: What is Terraform and how does it work?
**Answer:** Terraform is an Infrastructure as Code tool by HashiCorp that uses HCL (HashiCorp Configuration Language) to provision and manage cloud infrastructure.

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "web-server"
  }
}
```

### Q28: Terraform lifecycle: init, plan, apply, destroy
**Answer:**
```bash
terraform init      # Initialize provider plugins
terraform plan      # Preview changes
terraform apply    # Apply changes
terraform destroy  # Destroy resources
terraform show     # Show current state
terraform refresh # Refresh state
```

### Q29: What is Terraform state and why is it important?
**Answer:** State maps real-world resources to your configuration. It's stored in `terraform.tfstate`.

**Best practices:**
1. Use remote state (S3 + DynamoDB)
2. Enable state locking
3. Never edit state manually
4. Use workspaces for environments

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

### Q30: Terraform modules and their benefits
**Answer:** Modules are reusable Terraform configurations.

```hcl
# Using a module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## 6. Ansible & Configuration Management

### Q31: What is Ansible and how does it work?
**Answer:** Ansible is an open-source automation tool for configuration management, application deployment, and task automation using SSH (no agent required).

### Q32: Explain Ansible inventory.
**Answer:**
```ini
# inventory/hosts
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com

[all:vars]
ansible_user=admin
```

### Q33: What is the difference between Ansible playbook and role?
**Answer:**
- **Playbook:** YAML file defining tasks to execute
- **Role:** Reusable collection of tasks, handlers, templates, variables

### Q34: Ansible playbook example
**Answer:**
```yaml
---
- name: Configure Web Server
  hosts: webservers
  become: yes
  
  tasks:
  - name: Install nginx
    dnf:
      name: nginx
      state: present
  
  - name: Start nginx
    service:
      name: nginx
      state: started
      enabled: yes
  
  handlers:
  - name: restart nginx
    service:
      name: nginx
      state: restarted
```

---

## 7. Monitoring & Logging

### Q35: What is the difference between monitoring and logging?
**Answer:**
- **Monitoring:** Collecting metrics (CPU, memory, requests/sec)
- **Logging:** Recording events for debugging and audit

### Q36: Popular monitoring tools
**Answer:**
- **Prometheus + Grafana:** Open-source metrics and visualization
- **Datadog:** SaaS monitoring
- **CloudWatch:** AWS native monitoring
- **ELK Stack:** Elasticsearch, Logstash, Kibana
- **New Relic:** APM tool

### Q37: What is the ELK Stack?
**Answer:**
- **Elasticsearch:** Search and analytics engine
- **Logstash:** Log processing pipeline
- **Kibana:** Visualization dashboard

### Q38: Explain the Three Pillars of Observability
**Answer:**
1. **Metrics:** Numeric measurements (CPU%, request count)
2. **Logs:** Discrete events
3. **Traces:** Request flow across services

---

## 8. System Design & Architecture

### Q39: What is microservices architecture?
**Answer:** An architectural style that structures an application as a collection of loosely coupled services.

**Benefits:**
- Independent deployment
- Technology flexibility
- Scalability
- Fault isolation

**Challenges:**
- Network latency
- Data consistency
- Complex testing
- Service discovery

### Q40: How do you design a highly available system?
**Answer:**
1. Multiple availability zones
2. Load balancing
3. Auto-scaling
4. Database replication
5. Stateless applications
6. Circuit breakers
7. Graceful degradation
8. Regular backups

### Q41: What is the CAP theorem?
**Answer:** A distributed system can only guarantee 2 of 3:
- **Consistency:** All nodes see same data
- **Availability:** Every request gets response
- **Partition Tolerance:** System continues despite network failures

### Q42: What is 12-factor app methodology?
**Answer:**
1. Codebase - One repo per app
2. Dependencies - Explicitly declare
3. Config - Store in environment
4. Backing Services - Treat as attached resources
5. Build, Release, Run - Strict separation
6. Processes - Stateless
7. Port Binding - Export via port binding
8. Concurrency - Scale via processes
9. Disposability - Fast startup/shutdown
10. Dev/Prod Parity - Keep environments similar
11. Logs - Treat logs as event streams
12. Admin Processes - Run admin tasks same as app

---

## 9. Security & Compliance

### Q43: How do you secure containers?
**Answer:**
1. Use minimal base images
2. Scan images for vulnerabilities
3. Don't run as root
4. Use read-only root filesystems
5. Implement least privilege
6. Scan at build time (Trivy, Snyk)
7. Sign and verify images (Notary, Cosign)
8. Network segmentation

### Q44: What is DevSecOps?
**Answer:** Integrating security practices into DevOps processes:
- Shift-left security
- Automated security testing
- Security as code
- Continuous security monitoring

### Q45: How do you manage secrets securely?
**Answer:**
1. **Vault by HashiCorp:** Centralized secrets management
2. **AWS Secrets Manager:** AWS native solution
3. **Kubernetes Secrets:** Base64 encoded (not encryption)
4. **Environment variables:** Not recommended for production

### Q46: What is a Security Group vs NACL?
**Answer:**
- **Security Group:** Stateful, instance-level
- **NACL:** Stateless, subnet-level, applied before security group

---

## 10. Linux & Networking

### Q47: Common Linux commands for troubleshooting
**Answer:**
```bash
# Process management
ps aux | grep nginx
top / htop
kill -9 PID

# Network
netstat -tlnp
ss -tlnp
curl -v http://example.com
traceroute example.com
nslookup example.com

# Disk and memory
df -h
du -sh /var/log
free -h
iostat

# Logs
tail -f /var/log/nginx/access.log
grep ERROR /var/log/app.log
journalctl -u nginx
```

### Q48: Explain TCP/IP model layers
**Answer:**
1. **Application** (HTTP, SSH, DNS)
2. **Transport** (TCP, UDP)
3. **Internet** (IP)
4. **Link** (Ethernet)

### Q49: What is a reverse proxy vs forward proxy?
**Answer:**
- **Forward Proxy:** Client-side, hides client identity
- **Reverse Proxy:** Server-side, hides server identity, load balancing

### Q50: Common networking ports
**Answer:**
- **22:** SSH
- **80:** HTTP
- **443:** HTTPS
- **3306:** MySQL
- **5432:** PostgreSQL
- **6379:** Redis
- **9200:** Elasticsearch
- **9090:** Prometheus

---

## Bonus: Practical Scenarios

### Q51: How would you design a CI/CD pipeline for a microservices app?
**Answer:**
1. Monorepo with services in `/services/{service-name}/`
2. Each service has its own Dockerfile
3. Pipeline triggers on changes to specific service
4. Build and push service image
5. Deploy only changed services to staging
6. Run integration tests
7. Blue-green deployment to production
8. Monitor and rollback if needed

### Q52: How would you migrate from monolith to microservices?
**Answer:**
1. Identify bounded contexts
2. Start with strangler fig pattern
3. Extract services one by one
4. Set up API gateway
5. Implement service discovery
6. Add observability
7. Configure CI/CD per service
8. Decommission monolith parts

### Q53: How do you handle database migrations in CI/CD?
**Answer:**
1. Use migration tools (Flyway, Liquibase)
2. Migrations must be backward compatible
3. Run before deployment
4. Rollback strategy ready
5. Blue-green database migration pattern
6. Test migrations in staging first

---

## Quick Reference Commands

### Docker
```bash
docker build -t myapp:v1 .
docker run -d -p 80:80 myapp:v1
docker ps
docker logs -f container_id
docker exec -it container_id bash
docker-compose up -d
```

### Kubernetes
```bash
kubectl get pods
kubectl get svc
kubectl apply -f deployment.yaml
kubectl rollout status deployment/myapp
kubectl logs -f pod/myapp-pod
kubectl exec -it myapp-pod -- bash
kubectl scale deployment/myapp --replicas=5
```

### Terraform
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
terraform state list
terraform import aws_instance.existing i-12345
```

### Ansible
```bash
ansible all -m ping
ansible-playbook -i inventory site.yml --syntax-check
ansible-playbook -i inventory site.yml --check --diff
ansible-vault encrypt secrets.yml
```

---

**Good luck with your interviews!**
