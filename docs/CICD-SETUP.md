# CI/CD Setup Guide - Jenkins & SonarQube

Complete guide to setting up Jenkins and SonarQube on EC2 instances for production-grade CI/CD pipeline.

---

## 🎯 Overview

This guide covers:
- EC2 instance provisioning for Jenkins and SonarQube
- Installation and configuration of both tools
- Integration between Jenkins, SonarQube, AWS, and Kubernetes
- Troubleshooting common version conflicts

**⚠️ IMPORTANT:** We strongly recommend using EC2 instances instead of local machines to avoid:
- Version compatibility issues between different operating systems
- Inconsistent environments across team members
- Resource constraints on local machines
- Network/firewall complications

---

## 📋 Prerequisites

- AWS Account with EC2 permissions
- EC2 key pair created
- Basic understanding of Linux commands
- EKS cluster already deployed (from Phase 1)

---

## 🖥️ Part 1: EC2 Instance Setup

### Step 1.1: Launch Jenkins Server

**Instance Specifications:**
- **AMI:** Ubuntu 22.04 LTS (ami-0c55b159cbfafe1f0 for us-east-1)
- **Instance Type:** t3.medium (2 vCPU, 4GB RAM)
- **Storage:** 30GB gp3
- **Security Group:** Allow ports 8080 (Jenkins), 22 (SSH)

**Using AWS Console:**

1. Go to EC2 Dashboard → Launch Instance
2. Name: `Jenkins-Server`
3. Select Ubuntu 22.04 LTS
4. Instance type: t3.medium
5. Key pair: Select your existing key
6. Network settings:
   - Create security group or use existing
   - Allow SSH (22) from your IP
   - Allow Custom TCP (8080) from your IP
7. Configure storage: 30GB gp3
8. Launch instance

**Using AWS CLI:**

```bash
# Create security group
aws ec2 create-security-group \
  --group-name jenkins-sg \
  --description "Security group for Jenkins server" \
  --vpc-id vpc-xxxxx

# Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr YOUR_IP/32

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-name \
  --security-group-ids sg-xxxxx \
  --subnet-id subnet-xxxxx \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Jenkins-Server}]' \
  --iam-instance-profile Name=JenkinsEC2Role
```

### Step 1.2: Launch SonarQube Server

**Instance Specifications:**
- **AMI:** Ubuntu 22.04 LTS
- **Instance Type:** t3.medium (2 vCPU, 4GB RAM)
- **Storage:** 30GB gp3
- **Security Group:** Allow ports 9000 (SonarQube), 22 (SSH)

**Using AWS Console:**

Follow same steps as Jenkins but:
- Name: `SonarQube-Server`
- Security group: Allow port 9000 instead of 8080

**Using AWS CLI:**

```bash
# Create security group
aws ec2 create-security-group \
  --group-name sonarqube-sg \
  --description "Security group for SonarQube server" \
  --vpc-id vpc-xxxxx

# Add inbound rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 9000 \
  --cidr YOUR_IP/32

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-name \
  --security-group-ids sg-xxxxx \
  --subnet-id subnet-xxxxx \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SonarQube-Server}]'
```

### Step 1.3: Create IAM Role for Jenkins (Recommended)

Instead of using AWS credentials, attach an IAM role to Jenkins EC2:

```bash
# Create trust policy
cat > jenkins-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name JenkinsEC2Role \
  --assume-role-policy-document file://jenkins-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name JenkinsEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-role-policy \
  --role-name JenkinsEC2Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Create instance profile
aws iam create-instance-profile --instance-profile-name JenkinsEC2Role
aws iam add-role-to-instance-profile --instance-profile-name JenkinsEC2Role --role-name JenkinsEC2Role

# Attach to running instance
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=JenkinsEC2Role
```

---

## 🔧 Part 2: Jenkins Installation

### Step 2.1: Connect to Jenkins Server

```bash
# Get instance public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Jenkins-Server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# SSH into server
ssh -i your-key.pem ubuntu@<jenkins-server-ip>
```

### Step 2.2: Install Java 17

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 17 (required for Jenkins)
sudo apt install openjdk-17-jdk -y

# Verify installation
java -version
# Should show: openjdk version "17.x.x"
```

**⚠️ Version Note:** Jenkins 2.426+ requires Java 17. Do not use Java 11 or Java 21.

### Step 2.3: Install Jenkins

```bash
# Add Jenkins repository key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list
sudo apt update

# Install Jenkins
sudo apt install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
```

### Step 2.4: Initial Jenkins Setup

```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Access Jenkins:**
1. Open browser: `http://<jenkins-server-ip>:8080`
2. Enter the initial admin password
3. Click "Install suggested plugins"
4. Create admin user
5. Save and finish

### Step 2.5: Install Required Plugins

**Navigate to:** Manage Jenkins → Plugins → Available Plugins

Install the following plugins:

1. **NodeJS Plugin** - For Node.js builds
2. **SonarQube Scanner** - For code quality analysis
3. **Docker Pipeline** - For Docker operations
4. **AWS Credentials** - For AWS authentication
5. **Kubernetes CLI** - For kubectl commands
6. **Pipeline** - For pipeline jobs (usually pre-installed)
7. **Git** - For Git operations (usually pre-installed)

**After installation:** Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### Step 2.6: Configure Tools in Jenkins

**Navigate to:** Manage Jenkins → Tools

#### Configure NodeJS

1. Scroll to "NodeJS installations"
2. Click "Add NodeJS"
3. Name: `nodejs23`
4. Version: Select NodeJS 23.x
5. Save

#### Configure SonarQube Scanner

1. Scroll to "SonarQube Scanner installations"
2. Click "Add SonarQube Scanner"
3. Name: `sonar-scanner`
4. Install automatically from Maven Central
5. Version: Latest
6. Save

### Step 2.7: Install Additional Tools on Jenkins Server

```bash
# Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# Restart Jenkins to apply group changes
sudo systemctl restart jenkins

# Verify Docker
docker --version
```

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify kubectl
kubectl version --client
```

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Verify AWS CLI
aws --version
```

```bash
# Install Trivy (security scanner)
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

# Verify Trivy
trivy --version
```

```bash
# Install eksctl (optional, for EKS management)
curl --silent --location "https://github.com/weksctl/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify eksctl
eksctl version
```

### Step 2.8: Configure AWS Credentials in Jenkins

**Option A: Using IAM Role (Recommended)**

If you attached IAM role to EC2, Jenkins will automatically use it. No additional configuration needed!

**Option B: Using AWS Credentials**

1. Navigate to: Manage Jenkins → Credentials → System → Global credentials
2. Click "Add Credentials"
3. Kind: AWS Credentials
4. ID: `aws-creds`
5. Access Key ID: Your AWS access key
6. Secret Access Key: Your AWS secret key
7. Save

---

## 🔍 Part 3: SonarQube Installation

### Step 3.1: Connect to SonarQube Server

```bash
# Get instance public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=SonarQube-Server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# SSH into server
ssh -i your-key.pem ubuntu@<sonarqube-server-ip>
```

### Step 3.2: System Configuration

SonarQube requires specific system settings:

```bash
# Set kernel parameters
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
sudo sysctl -w vm.swappiness=1

# Make changes permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
echo "vm.swappiness=1" | sudo tee -a /etc/sysctl.conf

# Set ulimits
sudo bash -c 'cat >> /etc/security/limits.conf <<EOF
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF'
```

### Step 3.3: Install Docker

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Verify Docker
docker --version
```

### Step 3.4: Run SonarQube Container

```bash
# Run SonarQube
sudo docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  --restart unless-stopped \
  sonarqube:lts-community

# Check container status
sudo docker ps

# View logs
sudo docker logs -f sonarqube
```

**Wait 2-3 minutes** for SonarQube to start. You'll see "SonarQube is operational" in logs.

### Step 3.5: Access SonarQube

1. Open browser: `http://<sonarqube-server-ip>:9000`
2. Default credentials:
   - Username: `admin`
   - Password: `admin`
3. Change password when prompted

### Step 3.6: Create Project in SonarQube

1. Click "Create Project" → "Manually"
2. Project key: `prod-base-project`
3. Project name: `prod-base-project`
4. Click "Set Up"
5. Choose "Locally"
6. Generate token:
   - Token name: `jenkins-token`
   - Click "Generate"
   - **Copy and save this token!**

### Step 3.7: Configure SonarQube in Jenkins

**Add SonarQube Server:**

1. Jenkins → Manage Jenkins → System
2. Scroll to "SonarQube servers"
3. Click "Add SonarQube"
4. Name: `sonar`
5. Server URL: `http://<sonarqube-server-ip>:9000`
6. Server authentication token: Select credential (create new)
   - Kind: Secret text
   - Secret: Paste the token from SonarQube
   - ID: `sonar-token`
7. Save

---

## 🔗 Part 4: Integration & Testing

### Step 4.1: Configure EKS Access on Jenkins Server

```bash
# SSH into Jenkins server
ssh -i your-key.pem ubuntu@<jenkins-server-ip>

# Configure kubectl for EKS
aws eks update-kubeconfig --name production-prod-base-project-eks --region ap-south-1

# Test access
kubectl get nodes

# Copy kubeconfig to Jenkins user
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

### Step 4.2: Create ECR Repositories

```bash
# Create frontend repository
aws ecr create-repository \
  --repository-name prod-base-project/frontend \
  --region ap-south-1

# Create backend repository
aws ecr create-repository \
  --repository-name prod-base-project/backend \
  --region ap-south-1

# List repositories
aws ecr describe-repositories --region ap-south-1
```

### Step 4.3: Test Jenkins Pipeline

1. Create a new Pipeline job in Jenkins
2. Name: `test-pipeline`
3. Pipeline script:

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'nodejs23'
    }
    
    stages {
        stage('Test Tools') {
            steps {
                sh 'node --version'
                sh 'npm --version'
                sh 'docker --version'
                sh 'kubectl version --client'
                sh 'aws --version'
                sh 'trivy --version'
            }
        }
        
        stage('Test AWS Access') {
            steps {
                sh 'aws sts get-caller-identity'
                sh 'aws ecr describe-repositories --region ap-south-1'
            }
        }
        
        stage('Test EKS Access') {
            steps {
                sh 'kubectl get nodes'
            }
        }
    }
}
```

4. Click "Build Now"
5. Verify all stages pass

---

## 🐛 Troubleshooting

### Issue 1: Jenkins Can't Access Docker

**Error:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue 2: kubectl Command Not Found in Jenkins

**Error:** `kubectl: command not found`

**Solution:**
```bash
# Ensure kubectl is in PATH
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl

# Or add to Jenkins PATH
# Manage Jenkins → System → Global properties → Environment variables
# Name: PATH
# Value: /usr/local/bin:$PATH
```

### Issue 3: SonarQube Container Keeps Restarting

**Error:** `max virtual memory areas vm.max_map_count [65530] is too low`

**Solution:**
```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo docker restart sonarqube
```

### Issue 4: AWS CLI Not Configured

**Error:** `Unable to locate credentials`

**Solution:**
```bash
# If using IAM role, verify it's attached
aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].IamInstanceProfile'

# If using credentials
aws configure
```

### Issue 5: Node.js Version Conflicts

**Error:** `The engine "node" is incompatible with this module`

**Solution:**
- Ensure NodeJS 23 is configured in Jenkins Tools
- Check package.json for engine requirements
- Use nvm if multiple versions needed

### Issue 6: Trivy Database Update Fails

**Error:** `failed to download vulnerability DB`

**Solution:**
```bash
# Update Trivy database manually
trivy image --download-db-only

# Or skip DB update in pipeline
trivy image --skip-db-update <image>
```

---

## 📊 Verification Checklist

Before proceeding to application deployment:

- [ ] Jenkins accessible at port 8080
- [ ] SonarQube accessible at port 9000
- [ ] All Jenkins plugins installed
- [ ] NodeJS 23 configured in Jenkins
- [ ] SonarQube scanner configured
- [ ] AWS credentials configured (IAM role or credentials)
- [ ] Docker installed and accessible to Jenkins
- [ ] kubectl installed and configured for EKS
- [ ] AWS CLI installed and configured
- [ ] Trivy installed
- [ ] ECR repositories created
- [ ] Test pipeline runs successfully
- [ ] SonarQube project created
- [ ] SonarQube token added to Jenkins

---

## 🔐 Security Best Practices

1. **Use IAM Roles** instead of hardcoded credentials
2. **Restrict Security Groups** to your IP only
3. **Enable HTTPS** for Jenkins and SonarQube (use ALB + ACM)
4. **Regular Updates** - Keep Jenkins, plugins, and SonarQube updated
5. **Backup Jenkins** - Backup `/var/lib/jenkins` regularly
6. **Use Secrets Management** - Store sensitive data in AWS Secrets Manager
7. **Enable Audit Logs** - Track all Jenkins and SonarQube activities
8. **Multi-Factor Authentication** - Enable MFA for Jenkins admin users

---

## 📚 Additional Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

---

## 🎯 Next Steps

Once CI/CD tools are set up:

1. Return to main [README.md](../README.md)
2. Proceed to Phase 3: Application Deployment
3. Configure Jenkins pipeline for your application
4. Run your first deployment!

---

**✅ CI/CD Setup Complete!** You're now ready to deploy applications via Jenkins pipeline.
