# Docker Installation Guide for Rocky Linux 9.6

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Update System](#update-system)
3. [Install Docker](#install-docker)
4. [Start and Enable Docker](#start-and-enable-docker)
5. [Manage Docker as Non-Root User](#manage-docker-as-non-root-user)
6. [Verify Installation](#verify-installation)
7. [Configure Docker](#configure-docker)
8. [Install Docker Compose](#install-docker-compose)
9. [Troubleshooting](#troubleshooting)
10. [Uninstall Docker](#uninstall-docker)

---

## Prerequisites

### System Requirements
- Rocky Linux 9.6
- At least 2GB RAM
- 20GB available disk space
- Root or sudo privileges
- Internet connection

### Check System Version
```bash
cat /etc/os-release
# Should show: Rocky Linux 9.6 (Blue Onyx)
```

---

## Update System

### 1. Update All Packages
```bash
sudo dnf update -y
sudo dnf upgrade -y
```

### 2. Install Required Dependencies
```bash
sudo dnf install -y curl gnupg2 yum-utils
```

---

## Install Docker

### Method 1: From Docker Repository (Recommended)

#### Step 1: Add Docker's Official Repository
```bash
# Add Docker's official GPG key
sudo rpm --import https://download.docker.com/linux/rocky/gpg

# Add Docker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/rocky/docker-ce.repo
```

#### Step 2: Install Docker Engine
```bash
# Install Docker Engine, CLI, and containerd
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Method 2: From Rocky Linux AppStream (Alternative)

```bash
# Install Docker from AppStream
sudo dnf module enable -y container-tools
sudo dnf install -y docker-ce docker-ce-cli containerd.io
```

---

## Start and Enable Docker

### 1. Start Docker Service
```bash
sudo systemctl start docker
```

### 2. Enable Docker to Start on Boot
```bash
sudo systemctl enable docker
```

### 3. Check Docker Status
```bash
sudo systemctl status docker
```

Expected output should show:
```
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since ...
```

---

## Manage Docker as Non-Root User

### 1. Create Docker Group (if not exists)
```bash
sudo groupadd docker
```

### 2. Add Your User to Docker Group
```bash
# Replace 'yourusername' with your actual username
sudo usermod -aG docker yourusername

# Or add current user automatically
sudo usermod -aG docker $USER
```

### 3. Apply Group Changes
```bash
# Option 1: Log out and log back in
# Option 2: Run this command (temporary)
newgrp docker
```

### 4. Verify Non-Root Access
```bash
docker run hello-world
```

---

## Verify Installation

### 1. Test Docker with Hello World
```bash
docker run hello-world
```

Expected output:
```
Hello from Docker!
This message shows that your installation is working correctly.
```

### 2. Check Docker Version
```bash
docker --version
# Expected: Docker version 24.x.x

docker compose version
# Expected: Docker Compose version v2.x.x
```

### 3. Check System Information
```bash
docker info
```

### 4. Run Test Container
```bash
docker run --rm -it alpine:latest sh
# Type 'exit' to leave the container
```

---

## Configure Docker

### 1. Configure Docker Daemon
```bash
# Create Docker configuration directory
sudo mkdir -p /etc/docker

# Create daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false
}
EOF
```

### 2. Reload Docker Configuration
```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 3. Configure Docker Proxy (if needed)
```bash
# Create systemd drop-in directory for docker
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create proxy configuration file
sudo tee /etc/systemd/system/docker.service.d/proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

# Reload systemd and restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

## Install Docker Compose

### Method 1: Docker Compose Plugin (Recommended - Included)
If you installed using Method 1 above, Docker Compose is already included:
```bash
docker compose version
```

### Method 2: Standalone Docker Compose
```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Test Docker Compose
```bash
# Create a test docker-compose.yml
mkdir -p ~/docker-test
cd ~/docker-test

cat > docker-compose.yml <<EOF
version: '3.8'
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    restart: unless-stopped
EOF

# Start the service
docker compose up -d

# Check status
docker compose ps

# Stop and remove
docker compose down
cd ~
rm -rf ~/docker-test
```

---

## Advanced Configuration

### 1. Enable Experimental Features
```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "experimental": true,
  "features": {
    "buildkit": true
  }
}
EOF

sudo systemctl restart docker
```

### 2. Configure Log Rotation
```bash
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker
```

### 3. Set Default Storage Location
```bash
# Stop Docker
sudo systemctl stop docker

# Create new Docker directory
sudo mkdir -p /mnt/docker-data

# Edit Docker systemd service
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --data-root /mnt/docker-data
EOF

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl start docker
```

---

## Security Best Practices

### 1. Configure Docker Firewall
```bash
# Configure firewall for Docker
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
```

### 2. Enable Content Trust
```bash
# Enable Docker Content Trust for all commands
export DOCKER_CONTENT_TRUST=1
echo 'export DOCKER_CONTENT_TRUST=1' >> ~/.bashrc
```

### 3. Configure User Namespaces
```bash
# Add to daemon.json
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "userns-remap": "default"
}
EOF

sudo systemctl restart docker
```

---

## Common Docker Commands Cheat Sheet

### Container Management
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop <container_id>

# Start a container
docker start <container_id>

# Remove a container
docker rm <container_id>

# Execute commands in running container
docker exec -it <container_id> /bin/bash
```

### Image Management
```bash
# List images
docker images

# Pull an image
docker pull <image_name>

# Remove an image
docker rmi <image_id>

# Remove all unused images
docker image prune -a
```

### System Cleanup
```bash
# Remove all stopped containers
docker container prune

# Remove unused networks
docker network prune

# Remove all unused data
docker system prune -a
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Docker Service Won't Start
```bash
# Check status
sudo systemctl status docker

# Check logs
sudo journalctl -u docker.service

# Common fixes
sudo dnf install -y docker-selinux
sudo setenforce 0
sudo systemctl restart docker
```

#### 2. Permission Denied Error
```bash
# Check if user is in docker group
groups $USER

# If not, add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### 3. Docker Commands Hang
```bash
# Check Docker daemon
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check for conflicting processes
sudo lsof -i :2375
sudo lsof -i :2376
```

#### 4. Network Issues
```bash
# Reset Docker networking
sudo systemctl stop docker
sudo ip link delete docker0
sudo systemctl start docker

# Check network configuration
docker network ls
docker network inspect bridge
```

#### 5. Storage Issues
```bash
# Check disk usage
docker system df

# Clean up unused data
docker system prune -a

# Check Docker directory size
sudo du -sh /var/lib/docker/
```

### Performance Tuning

#### 1. Optimize Docker Performance
```bash
# Configure Docker daemon for better performance
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
EOF

sudo systemctl restart docker
```

#### 2. Monitor Docker Resources
```bash
# Install monitoring tools
sudo dnf install -y htop iotop

# Monitor Docker processes
docker stats
docker stats --no-stream

# Monitor system resources
htop
iotop
```

---

## Uninstall Docker

### Complete Docker Removal
```bash
# Stop Docker service
sudo systemctl stop docker

# Remove Docker packages
sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Remove Docker data and directories
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker

# Remove Docker group
sudo groupdel docker

# Remove systemd service files
sudo rm -f /etc/systemd/system/docker.service.d/*.conf
sudo systemctl daemon-reload
```

### Clean Up Network Settings
```bash
# Remove Docker network interfaces
sudo ip link delete docker0
sudo iptables -F DOCKER-USER
sudo iptables -F DOCKER-ISOLATION-STAGE-1
sudo iptables -F DOCKER-ISOLATION-STAGE-2
```

---

## Next Steps

### 1. Deploy Your First Application
```bash
# Create a simple web application
mkdir -p ~/myapp
cd ~/myapp

# Create Dockerfile
cat > Dockerfile <<EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EOF

# Create index.html
cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Hello Docker</title></head>
<body><h1>Hello from Docker on Rocky Linux!</h1></body>
</html>
EOF

# Build and run
docker build -t myapp .
docker run -d -p 8080:80 myapp

# Test
curl http://localhost:8080
```

### 2. Explore Docker Features
- Docker Volumes for data persistence
- Docker Networks for container communication
- Docker Compose for multi-container applications
- Docker Registry for image management
- Docker Swarm for orchestration

### 3. Security Considerations
- Regular security updates
- Image scanning
- Network segmentation
- Access control and logging

---

## Additional Resources

### Official Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Rocky Linux Documentation](https://docs.rockylinux.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Community Resources
- [Docker Forums](https://forums.docker.com/)
- [Rocky Linux Forums](https://forums.rockylinux.org/)
- [Reddit r/docker](https://reddit.com/r/docker)

### Video Tutorials
- [Docker Official YouTube Channel](https://www.youtube.com/c/Docker)
- [Rocky Linux YouTube Channel](https://www.youtube.com/c/RockyLinux)

---

## Quick Reference

### Installation Commands Summary
```bash
# Update system
sudo dnf update -y && sudo dnf upgrade -y

# Install dependencies
sudo dnf install -y curl gnupg2 yum-utils

# Add Docker repository
sudo rpm --import https://download.docker.com/linux/rocky/gpg
sudo dnf config-manager --add-repo https://download.docker.com/linux/rocky/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker run hello-world
```

### Essential Commands
```bash
# Check Docker status
sudo systemctl status docker

# View system info
docker info

# View version
docker --version
docker compose version

# Clean up
docker system prune -a
```

---

**🎉 Congratulations!** You now have Docker installed and running on Rocky Linux 9.6. You can start building and deploying containers immediately!