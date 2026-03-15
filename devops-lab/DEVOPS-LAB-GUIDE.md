# DevOps Lab Project - Complete Step by Step Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Server Setup](#server-setup)
4. [Ansible Configuration](#ansible-configuration)
5. [Base Security Playbook](#base-security-playbook)
6. [DNS Server Configuration](#dns-server-configuration)
7. [Web Servers & Load Balancer](#web-servers--load-balancer)
8. [Database Server (MariaDB)](#database-server-mariadb)
9. [Nagios Monitoring](#nagios-monitoring)
10. [Docker Configuration](#docker-configuration)
11. [Kubernetes Setup](#kubernetes-setup)
12. [Running the Playbooks](#running-the-playbooks)
13. [Verification & Testing](#verification--testing)

---

## Project Overview

This project deploys a complete DevOps lab infrastructure with:
- 10 Servers (DNS, Database, 3 Webservers, Load Balancer, Nagios, Ansible, Docker, Kubernetes)
- Ansible automation for all configurations
- Complete monitoring with Nagios
- Load balanced web infrastructure
- Docker containerized application
- Kubernetes cluster

---

## Prerequisites

### 1. Create 10 Virtual Machines

| Server Name | IP Address | RAM | CPU | Disk |
|-------------|------------|-----|-----|------|
| prdx-dns101 | 192.168.100.10 | 1G | 1 | 5G |
| prdx-db101 | 192.168.100.20 | 1G | 1 | 5G |
| prdx-webserver101 | 192.168.100.31 | 1G | 1 | 5G |
| prdx-webserver102 | 192.168.100.32 | 1G | 1 | 5G |
| prdx-webserver103 | 192.168.100.33 | 1G | 1 | 5G |
| prdx-haproxy101 | 192.168.100.40 | 1G | 1 | 5G |
| prdx-nagios101 | 192.168.100.50 | 1G | 1 | 5G |
| prdx-ansible101 | 192.168.100.60 | 1G | 1 | 5G |
| prdx-dprimary101 | 192.168.100.70 | 4G | 4 | 15G |
| prdx-kube101 | 192.168.100.80 | 3G | 1 | 5G |

### 2. Install Rocky Linux 9 on All VMs

### 3. Configure Network
```bash
# On each VM, configure static IP
nmcli con mod eth0 ipv4.addresses 192.168.100.X/24 ipv4.gateway 192.168.100.1 ipv4.dns "192.168.100.10" ipv4.method manual
nmcli con up eth0
```

---

## Ansible Configuration

### Step 1: Install Ansible on prdx-ansible101

```bash
# SSH to ansible server
ssh root@192.168.100.60

# Install Ansible
dnf install -y epel-release
dnf install -y ansible

# Verify installation
ansible --version
```

### Step 2: Setup SSH Key Authentication

```bash
# On ansible server, generate SSH key
ssh-keygen -t rsa -b 4096 -C "ansible@lab.local"

# Copy SSH key to all servers
ssh-copy-id root@192.168.100.10  # DNS
ssh-copy-id root@192.168.100.20  # DB
ssh-copy-id root@192.168.100.31  # Web1
ssh-copy-id root@192.168.100.32  # Web2
ssh-copy-id root@192.168.100.33  # Web3
ssh-copy-id root@192.168.100.40  # LB
ssh-copy-id root@192.168.100.50  # Nagios
ssh-copy-id root@192.168.100.60  # Ansible
ssh-copy-id root@192.168.100.70  # Docker
ssh-copy-id root@192.168.100.80  # K8s
```

### Step 3: Create Ansible User on All Servers

```bash
# On EACH server, create ansible user
useradd -m -s /bin/bash ansible
echo "ansible:password" | chpasswd
echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible

# Allow ansible user SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
```

### Step 4: Copy SSH Keys for Ansible User

```bash
# As root on ansible server
su - ansible
ssh-keygen -t rsa -b 4096
ssh-copy-id ansible@192.168.100.10
ssh-copy-id ansible@192.168.100.20
# ... repeat for all servers
```

---

## Base Security Playbook

### Create the Playbook

Create file: `ansible/playbooks/base-security.yml`

```bash
mkdir -p ansible/playbooks
```

```yaml
---
- name: Base Security Configuration
  hosts: all
  become: true
  vars:
    ansible_user: ansible
    ansible_password: password
    root_password: "password"
  
  tasks:
    # Disable SELinux
    - name: Disable SELinux
      selinux:
        state: disabled
      ignore_errors: yes

    - name: Set SELinux to permissive
      command: setenforce 0
      changed_when: false
      ignore_errors: yes

    # Configure Firewall
    - name: Install firewalld
      dnf:
        name: firewalld
        state: present

    - name: Start and enable firewalld
      service:
        name: firewalld
        state: started
        enabled: yes

    - name: Allow SSH through firewall
      firewalld:
        service: ssh
        permanent: yes
        state: enabled

    # Disable Root Login
    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: restart sshd

    # Install Common Packages
    - name: Install common packages
      dnf:
        name:
          - bind-utils
          - man
          - man-pages
          - mlocate
          - sysstat
          - vim
          - wget
          - curl
          - git
        state: present

    # Configure Password
    - name: Set root password
      user:
        name: root
        password: "{{ root_password | password_hash('sha512') }}"

    - name: Configure ansible user
      user:
        name: ansible
        password: "{{ ansible_password | password_hash('sha512') }}"
        groups: wheel
        append: yes

    - name: Sudo without password
      lineinfile:
        path: /etc/sudoers.d/ansible
        line: 'ansible ALL=(ALL) NOPASSWD: ALL'
        create: yes
        mode: '0440'

    # Update locate database
    - name: Update mlocate database
      command: updatedb
      changed_when: false

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

### Run Base Security Playbook

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/base-security.yml --ask-pass
```

---

## DNS Server Configuration

### Create DNS Playbook

Create file: `ansible/playbooks/dns-server.yml`

```yaml
---
- name: Configure DNS Server
  hosts: prdx-dns101
  become: true
  
  tasks:
    - name: Install BIND
      dnf:
        name:
          - bind
          - bind-utils
        state: present

    - name: Configure named.conf
      template:
        src: templates/named.conf.j2
        dest: /etc/named.conf
        mode: '0644'
      notify: restart named

    - name: Create forward zone
      template:
        src: templates/zone.forward.j2
        dest: /var/named/forward.lab.local
        mode: '0640'
        group: named
      notify: restart named

    - name: Create reverse zone
      template:
        src: templates/zone.reverse.j2
        dest: /var/named/reverse.100.168.192.in-addr.arpa
        mode: '0640'
        group: named
      notify: restart named

    - name: Start named service
      service:
        name: named
        state: started
        enabled: yes

    - name: Allow DNS through firewall
      firewalld:
        service: dns
        permanent: yes
        state: enabled

  handlers:
    - name: restart named
      service:
        name: named
        state: restarted
```

### Create DNS Templates

**templates/named.conf.j2:**
```conf
options {
    listen-on port 53 { any; };
    directory "/var/named";
    allow-query { any; };
    recursion yes;
};

zone "lab.local" IN {
    type master;
    file "forward.lab.local";
};

zone "100.168.192.in-addr.arpa" IN {
    type master;
    file "reverse.100.168.192.in-addr.arpa";
};
```

**templates/zone.forward.j2:**
```
$TTL 86400
@       IN SOA  lab.local. admin.lab.local. (2024010101 3600 1800 604800 86400)
@       IN NS      prdx-dns101.lab.local.
prdx-dns101     IN A       192.168.100.10
prdx-db101      IN A       192.168.100.20
prdx-webserver101 IN A    192.168.100.31
prdx-webserver102 IN A    192.168.100.32
prdx-webserver103 IN A    192.168.100.33
prdx-haproxy101  IN A      192.168.100.40
prdx-nagios101   IN A      192.168.100.50
prdx-ansible101  IN A      192.168.100.60
prdx-dprimary101 IN A      192.168.100.70
prdx-kube101     IN A      192.168.100.80
```

**templates/zone.reverse.j2:**
```
$TTL 86400
@       IN SOA  lab.local. admin.lab.local. (2024010101 3600 1800 604800 86400)
@       IN NS      prdx-dns101.lab.local.
10      IN PTR     prdx-dns101.lab.local.
20      IN PTR     prdx-db101.lab.local.
31      IN PTR     prdx-webserver101.lab.local.
32      IN PTR     prdx-webserver102.lab.local.
33      IN PTR     prdx-webserver103.lab.local.
40      IN PTR     prdx-haproxy101.lab.local.
50      IN PTR     prdx-nagios101.lab.local.
60      IN PTR     prdx-ansible101.lab.local.
70      IN PTR     prdx-dprimary101.lab.local.
80      IN PTR     prdx-kube101.lab.local.
```

### Run DNS Playbook

```bash
ansible-playbook -i inventory/hosts playbooks/dns-server.yml
```

---

## Web Servers & Load Balancer

### Create Web Server Playbook

**playbooks/web-servers.yml:**
```yaml
---
- name: Configure Web Servers
  hosts: webservers
  become: true
  
  tasks:
    - name: Install Apache and PHP
      dnf:
        name:
          - httpd
          - php
          - php-mysql
        state: present

    - name: Create index.html
      template:
        src: templates/index.html.j2
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Start Apache
      service:
        name: httpd
        state: started
        enabled: yes

    - name: Allow HTTP/HTTPS
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
      loop:
        - http
        - https
```

### Create HAProxy Playbook

**playbooks/loadbalancer.yml:**
```yaml
---
- name: Configure HAProxy Load Balancer
  hosts: prdx-haproxy101
  become: true
  
  tasks:
    - name: Install HAProxy
      dnf:
        name: haproxy
        state: present

    - name: Configure HAProxy
      template:
        src: templates/haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
        mode: '0644'
      notify: restart haproxy

    - name: Start HAProxy
      service:
        name: haproxy
        state: started
        enabled: yes

    - name: Allow HTTP/HTTPS
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
      loop:
        - http
        - https

  handlers:
    - name: restart haproxy
      service:
        name: haproxy
        state: restarted
```

### HAProxy Configuration Template

**templates/haproxy.cfg.j2:**
```
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  forwardfor
    option                  http-server-close
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s

listen stats
    bind :8888
    mode http
    stats enable
    stats uri /stats

frontend http_front
    bind *:80
    mode http
    default_backend web_back

backend web_back
    mode http
    balance roundrobin
    option httpchk
    server web1 192.168.100.31:80 check inter 2000 rise 2 fall 3
    server web2 192.168.100.32:80 check inter 2000 rise 2 fall 3
    server web3 192.168.100.33:80 check inter 2000 rise 2 fall 3
```

### Run Web & LB Playbooks

```bash
ansible-playbook -i inventory/hosts playbooks/web-servers.yml
ansible-playbook -i inventory/hosts playbooks/loadbalancer.yml
```

### Verify Load Balancer

```bash
# Test from browser
# Go to http://192.168.100.40
# Refresh to see different server IDs

# Or use curl
curl http://192.168.100.40
curl http://192.168.100.40
curl http://192.168.100.40
```

---

## Database Server (MariaDB)

### Create Database Playbook

**playbooks/database.yml:**
```yaml
---
- name: Configure MariaDB
  hosts: prdx-db101
  become: true
  
  tasks:
    - name: Install MariaDB
      dnf:
        name:
          - mariadb-server
          - mariadb
        state: present

    - name: Start MariaDB
      service:
        name: mariadb
        state: started
        enabled: yes

    - name: Create database
      community.mysql.mysql_db:
        name: devops_lab
        state: present

    - name: Create user
      community.mysql.mysql_user:
        name: devops_user
        password: password
        priv: 'devops_lab.*:ALL'
        state: present

    - name: Create sample data
      community.mysql.mysql_query:
        login_user: root
        query:
          - "USE devops_lab;"
          - "CREATE TABLE IF NOT EXISTS employees (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), state VARCHAR(50), department VARCHAR(50), salary DECIMAL(10,2));"
          - "INSERT INTO employees (name, state, department, salary) VALUES ('John Doe', 'California', 'Engineering', 75000.00);"
          - "INSERT INTO employees (name, state, department, salary) VALUES ('Jane Smith', 'Texas', 'Sales', 65000.00);"
          - "INSERT INTO employees (name, state, department, salary) VALUES ('Bob Johnson', 'New York', 'Marketing', 70000.00);"
```

### Run Database Playbook

```bash
ansible-playbook -i inventory/hosts playbooks/database.yml
```

### Verify Database

```bash
# SSH to DB server
ssh ansible@192.168.100.20

# Connect to MariaDB
mysql -u devops_user -p devops_lab

# Check data
SHOW TABLES;
SELECT * FROM employees;
```

---

## Nagios Monitoring

### Install NRPE on All Clients First

**playbooks/nrpe-client.yml:**
```yaml
---
- name: Install NRPE on all servers
  hosts: all
  become: true
  
  tasks:
    - name: Install EPEL and NRPE
      dnf:
        name:
          - epel-release
          - nrpe
          - nagios-plugins-all
        state: present

    - name: Configure NRPE
      lineinfile:
        path: /etc/nagios/nrpe.cfg
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^allowed_hosts=', line: 'allowed_hosts=127.0.0.1,192.168.100.50' }
        - { regexp: '^dont_blame_nrpe=', line: 'dont_blame_nrpe=1' }
      notify: restart nrpe

    - name: Start NRPE
      service:
        name: nrpe
        state: started
        enabled: yes

    - name: Allow NRPE port
      firewalld:
        port: 5666/tcp
        permanent: yes
        state: enabled

  handlers:
    - name: restart nrpe
      service:
        name: nrpe
        state: restarted
```

### Create Nagios Server Playbook

**playbooks/nagios-server.yml:**
```yaml
---
- name: Configure Nagios Server
  hosts: prdx-nagios101
  become: true
  
  tasks:
    - name: Install Nagios
      dnf:
        name:
          - nagios
          - nagios-plugins-all
          - httpd
          - php
        state: present

    - name: Create Nagios admin user
      htpasswd:
        path: /etc/nagios/passwd
        name: nagiosadmin
        password: nagios
        create: yes

    - name: Configure Apache for Nagios
      template:
        src: templates/nagios.conf.j2
        dest: /etc/httpd/conf.d/nagios.conf
        mode: '0644'
      notify: restart httpd

    - name: Create hosts config
      template:
        src: templates/hosts.cfg.j2
        dest: /etc/nagios/conf.d/hosts.cfg
        mode: '0644'
      notify: restart nagios

    - name: Create services config
      template:
        src: templates/services.cfg.j2
        dest: /etc/nagios/conf.d/services.cfg
        mode: '0644'
      notify: restart nagios

    - name: Start services
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop:
        - nagios
        - httpd

  handlers:
    - name: restart nagios
      service:
        name: nagios
        state: restarted

    - name: restart httpd
      service:
        name: httpd
        state: restarted
```

### Run Nagios Playbooks

```bash
ansible-playbook -i inventory/hosts playbooks/nrpe-client.yml
ansible-playbook -i inventory/hosts playbooks/nagios-server.yml
```

### Verify Nagios

```bash
# Access Nagios GUI
# URL: http://192.168.100.50/nagios
# Username: nagiosadmin
# Password: nagios
```

---

## Docker Configuration

### Create Docker Playbook

**playbooks/docker.yml:**
```yaml
---
- name: Configure Docker Server
  hosts: prdx-dprimary101
  become: true
  
  tasks:
    - name: Install Docker dependencies
      dnf:
        name:
          - dnf-plugins-core
          - python3-pip
        state: present

    - name: Add Docker repo
      get_url:
        url: https://download.docker.com/linux/centos/docker-ce.repo
        dest: /etc/yum.repos.d/docker-ce.repo

    - name: Install Docker
      dnf:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present

    - name: Start Docker
      service:
        name: docker
        state: started
        enabled: yes

    - name: Download app
      get_url:
        url: https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/CUR-TF-200-ACACAD/studentdownload/lab-app.tgz
        dest: /tmp/lab-app.tgz
      ignore_errors: yes

    - name: Create app directory
      file:
        path: /opt/docker-app
        state: directory

    - name: Create Dockerfile
      copy:
        dest: /opt/docker-app/Dockerfile
        content: |
          FROM rockylinux:9
          RUN dnf install -y httpd php php-mysql && dnf clean all
          RUN mkdir -p /var/www/html
          COPY rds.conf.php /var/www/html/ 2>/dev/null || true
          EXPOSE 80
          CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
        mode: '0644'

    - name: Build Docker image
      community.docker.docker_image:
        name: devops-app
        tag: latest
        build:
          path: /opt/docker-app
        source: build
        state: present
      ignore_errors: yes

    - name: Run container
      community.docker.docker_container:
        name: devops-app
        image: devops-app:latest
        state: started
        ports:
          - "8080:80"
        restart_policy: always
      ignore_errors: yes
```

### Run Docker Playbook

```bash
ansible-playbook -i inventory/hosts playbooks/docker.yml
```

### Verify Docker

```bash
# Check running containers
docker ps

# Test website
curl http://192.168.100.70:8080
```

---

## Kubernetes Setup

### Create Kubernetes Playbook

**playbooks/kubernetes.yml:**
```yaml
---
- name: Configure Kubernetes (Minikube)
  hosts: prdx-kube101
  become: true
  
  tasks:
    - name: Install kubectl
      dnf:
        name:
          - kubectl
        state: present
      ignore_errors: yes

    - name: Install Minikube
      get_url:
        url: https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        dest: /usr/local/bin/minikube
        mode: '0755'

    - name: Install Docker
      dnf:
        name:
          - docker-ce
          - docker-ce-cli
        state: present
      ignore_errors: yes

    - name: Start Docker
      service:
        name: docker
        state: started
        enabled: yes

    - name: Add user to docker group
      user:
        name: ansible
        groups: docker
        append: yes

    - name: Start Minikube
      command: minikube start --driver=docker --cpus=2 --memory=2048
      args:
        creates: /home/ansible/.minikube
      become_user: ansible
      ignore_errors: yes
```

### Run Kubernetes Playbook

```bash
ansible-playbook -i inventory/hosts playbooks/kubernetes.yml
```

### Verify Kubernetes

```bash
# SSH to kube server
ssh ansible@192.168.100.80

# Check Minikube status
minikube status
minikube dashboard --url
kubectl get nodes
kubectl get pods --all-namespaces
```

---

## Running the Playbooks

### Option 1: Run Individual Playbooks

```bash
# Base security (run first!)
ansible-playbook -i inventory/hosts playbooks/base-security.yml

# DNS
ansible-playbook -i inventory/hosts playbooks/dns-server.yml

# Web servers
ansible-playbook -i inventory/hosts playbooks/web-servers.yml

# Load balancer
ansible-playbook -i inventory/hosts playbooks/loadbalancer.yml

# Database
ansible-playbook -i inventory/hosts playbooks/database.yml

# NRPE clients
ansible-playbook -i inventory/hosts playbooks/nrpe-client.yml

# Nagios
ansible-playbook -i inventory/hosts playbooks/nagios-server.yml

# Docker
ansible-playbook -i inventory/hosts playbooks/docker.yml

# Kubernetes
ansible-playbook -i inventory/hosts playbooks/kubernetes.yml
```

### Option 2: Run All at Once

Create **site.yml:**
```yaml
---
- import_playbook: base-security.yml
- import_playbook: dns-server.yml
- import_playbook: web-servers.yml
- import_playbook: loadbalancer.yml
- import_playbook: database.yml
- import_playbook: nrpe-client.yml
- import_playbook: nagios-server.yml
- import_playbook: docker.yml
- import_playbook: kubernetes.yml
```

```bash
ansible-playbook -i inventory/hosts playbooks/site.yml
```

---

## Verification & Testing

### 1. Test Ansible Connectivity

```bash
# Ping all hosts
ansible all -i inventory/hosts -m ping

# Check DNS resolution
ansible all -i inventory/hosts -m shell -a "cat /etc/resolv.conf"

# Check hosts file
ansible all -i inventory/hosts -m shell -a "cat /etc/hosts"
```

### 2. Test DNS

```bash
# From any server
nslookup prdx-webserver101 192.168.100.10
nslookup prdx-db101 192.168.100.10
```

### 3. Test Load Balancer

```bash
# Access via browser
# http://192.168.100.40

# Or curl multiple times
for i in {1..10}; do curl http://192.168.100.40; done
```

### 4. Test Database

```bash
# SSH to DB server
ssh ansible@192.168.100.20
mysql -u devops_user -p -e "USE devops_lab; SELECT * FROM employees;"
```

### 5. Test Nagios

```bash
# Access GUI
# http://192.168.100.50/nagios
# Username: nagiosadmin
# Password: nagios
```

### 6. Test Docker

```bash
# Check container
curl http://192.168.100.70:8080
```

### 7. Test Kubernetes

```bash
# SSH to kube server
ssh ansible@192.168.100.80

# Check cluster
kubectl get nodes
kubectl get pods -A
```

---

## Quick Troubleshooting

### Ansible Issues

```bash
# Reset connection
ansible all -i inventory/hosts -m ping

# Check SSH
ssh -v ansible@192.168.100.X
```

### Service Issues

```bash
# Check service status
systemctl status httpd
systemctl status haproxy
systemctl status named
systemctl status mariadb
systemctl status nagios
systemctl status docker
```

### Network Issues

```bash
# Check firewall
firewall-cmd --list-all

# Check DNS
nslookup google.com 192.168.100.10

# Test connectivity
ping 192.168.100.X
```

---

## Project Summary

After completing all steps, you will have:

| Component | URL/Command |
|-----------|-------------|
| Ansible | `ansible all -m ping` |
| DNS | 192.168.100.10 |
| Web Servers | 192.168.100.31-33 |
| Load Balancer | http://192.168.100.40 |
| HAProxy Stats | http://192.168.100.40:8888/stats |
| Database | 192.168.100.20:3306 |
| Nagios | http://192.168.100.50/nagios |
| Docker | http://192.168.100.70:8080 |
| Kubernetes | minikube dashboard |

---

**🎉 Congratulations! Your DevOps Lab is now fully configured!**
