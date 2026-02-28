# Production-Grade AWS EKS Infrastructure with CI/CD Pipeline

A complete end-to-end production infrastructure project featuring AWS EKS, Terraform IaC, Jenkins CI/CD, and comprehensive DevSecOps practices.

![Architecture](https://img.shields.io/badge/AWS-EKS-orange) ![Terraform](https://img.shields.io/badge/IaC-Terraform-purple) ![Jenkins](https://img.shields.io/badge/CI/CD-Jenkins-red) ![Kubernetes](https://img.shields.io/badge/K8s-1.28-blue)

## 🎯 Project Overview

This project demonstrates a production-ready infrastructure setup with:

- **Infrastructure as Code** using Terraform
- **Container Orchestration** with AWS EKS (Kubernetes)
- **CI/CD Pipeline** with Jenkins
- **Security Scanning** with SonarQube and Trivy
- **Monitoring & Observability** with Prometheus and Grafana
- **3-Tier Application** deployment (Frontend, Backend, Database)

**Perfect for:** DevOps Engineers, Cloud Architects, and teams looking to implement production-grade infrastructure.

---

## 📁 Project Structure

```
Prod-base-project/
├── terraform-resources/          # Infrastructure as Code
│   ├── bootstrap/                # Remote state backend (S3 + DynamoDB)
│   ├── modules/                  # Reusable Terraform modules
│   │   ├── vpc/                  # VPC with public/private subnets
│   │   ├── eks/                  # EKS cluster + node groups
│   │   ├── rds/                  # PostgreSQL database
│   │   ├── bastion/              # Bastion host for secure access
│   │   ├── security-groups/      # Security group rules
│   │   └── secrets/              # AWS Secrets Manager
│   └── environments/
│       └── production/           # Production environment config
│
├── application/                  # 3-Tier application code
│   ├── 3-Tier-DevSecOps-Mega-Project/
│   │   ├── client/               # React frontend
│   │   └── api/                  # Node.js backend
│   └── k8s-prod/                 # Kubernetes manifests
│
├── monitoring/                   # Prometheus + Grafana setup
├── docs/                         # Detailed documentation
├── Jenkinsfile                   # CI/CD pipeline definition
└── README.md                     # This file
```

---

## 🚀 Quick Start Guide

### Prerequisites

Before starting, ensure you have:

- AWS Account with appropriate permissions
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- kubectl >= 1.28
- Docker installed
- Git installed

### Deployment Overview

This project follows a **3-phase deployment**:

1. **Phase 1:** Deploy AWS Infrastructure (Terraform)
2. **Phase 2:** Setup CI/CD Tools (Jenkins + SonarQube)
3. **Phase 3:** Deploy Application via CI/CD Pipeline

---

## 📖 Step-by-Step Deployment

### Phase 1: Infrastructure Deployment

**Time Required:** ~30 minutes

#### Step 1.1: Setup Remote State Backend

```bash
cd terraform-resources/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

#### Step 1.2: Deploy EKS Infrastructure

```bash
cd ../environments/production
cp terraform.tfvars.example terraform.tfvars
```

**⚠️ IMPORTANT:** Edit `terraform.tfvars` and update:
- `key_name` - Your EC2 key pair name
- `allowed_ssh_cidrs` - Your IP address (not 0.0.0.0/0)
- `db_master_password` - Strong password

```bash
terraform init
terraform apply
```

This deploys:
- VPC with 8 subnets (public/private across 2 AZs)
- EKS cluster with managed node groups
- RDS PostgreSQL database
- Bastion host
- Security groups
- KMS encryption keys

#### Step 1.3: Configure kubectl

```bash
aws eks update-kubeconfig --name production-prod-base-project-eks --region ap-south-1
kubectl get nodes
```

**✅ Checkpoint:** You should see 2-4 EKS nodes in Ready state.

**📚 Detailed Guide:** See [terraform-resources/README.md](terraform-resources/README.md)

---

### Phase 2: CI/CD Tools Setup

**Time Required:** ~45 minutes

**⚠️ RECOMMENDATION:** Use EC2 instances for Jenkins and SonarQube (not local machine) to avoid version conflicts and ensure consistent environment.

#### Step 2.1: Launch EC2 Instances

**Option A: Using AWS Console**
1. Launch 2 EC2 instances (Ubuntu 22.04 LTS)
   - **Jenkins Server:** t3.medium (2 vCPU, 4GB RAM)
   - **SonarQube Server:** t3.medium (2 vCPU, 4GB RAM)
2. Configure security groups:
   - Jenkins: Port 8080 (HTTP), 22 (SSH)
   - SonarQube: Port 9000 (HTTP), 22 (SSH)
3. Attach IAM role with ECR and EKS permissions

**Option B: Using AWS CLI**
```bash
# Create Jenkins server
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-name \
  --security-group-ids sg-xxxxx \
  --subnet-id subnet-xxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Jenkins-Server}]'

# Create SonarQube server
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-name \
  --security-group-ids sg-xxxxx \
  --subnet-id subnet-xxxxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=SonarQube-Server}]'
```

#### Step 2.2: Install Jenkins

SSH into Jenkins server:
```bash
ssh -i your-key.pem ubuntu@<jenkins-server-ip>
```

Run installation script:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Java 17
sudo apt install openjdk-17-jdk -y
java -version

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Access Jenkins:** `http://<jenkins-server-ip>:8080`

#### Step 2.3: Configure Jenkins

1. **Install Required Plugins:**
   - Manage Jenkins → Plugins → Available Plugins
   - Install:
     - NodeJS Plugin
     - SonarQube Scanner
     - Docker Pipeline
     - AWS Credentials
     - Kubernetes CLI

2. **Configure Tools:**
   - Manage Jenkins → Tools
   - **NodeJS:** Add NodeJS 23 (name: `nodejs23`)
   - **SonarQube Scanner:** Add scanner (name: `sonar-scanner`)

3. **Add AWS Credentials:**
   - Manage Jenkins → Credentials → System → Global credentials
   - Add AWS credentials (ID: `aws-creds`)
   - Add SonarQube token (ID: `sonar-token`)

#### Step 2.4: Install SonarQube

SSH into SonarQube server:
```bash
ssh -i your-key.pem ubuntu@<sonarqube-server-ip>
```

Run installation:
```bash
# System configuration
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf

# Install Docker
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Run SonarQube
sudo docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community

# Check status
sudo docker ps
sudo docker logs -f sonarqube
```

**Access SonarQube:** `http://<sonarqube-server-ip>:9000`
- Default credentials: `admin` / `admin`
- Change password on first login

#### Step 2.5: Configure SonarQube

1. Create new project:
   - Project key: `prod-base-project`
   - Project name: `prod-base-project`
2. Generate token:
   - My Account → Security → Generate Token
   - Save token for Jenkins configuration
3. Add token to Jenkins:
   - Jenkins → Manage Jenkins → Credentials
   - Add Secret Text (ID: `sonar-token`)

#### Step 2.6: Install Additional Tools on Jenkins Server

```bash
# Install Docker
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Install Trivy (security scanner)
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
trivy --version

# Configure AWS CLI (use IAM role or credentials)
aws configure
```

**✅ Checkpoint:** 
- Jenkins accessible at port 8080
- SonarQube accessible at port 9000
- All tools installed and configured

**📚 Detailed Guide:** See [docs/CICD-SETUP.md](docs/CICD-SETUP.md)

---

### Phase 3: Application Deployment

**Time Required:** ~20 minutes

#### Step 3.1: Create ECR Repositories

```bash
aws ecr create-repository --repository-name prod-base-project/frontend --region ap-south-1
aws ecr create-repository --repository-name prod-base-project/backend --region ap-south-1
```

#### Step 3.2: Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=production-prod-base-project-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region=ap-south-1 \
  --approve

# Install controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-prod-base-project-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

#### Step 3.3: Setup Jenkins Pipeline

1. **Create Pipeline Job:**
   - Jenkins → New Item → Pipeline
   - Name: `prod-base-project-cicd`
   - Pipeline script from SCM
   - Repository URL: `https://github.com/your-username/prod-base-project.git`
   - Branch: `main`
   - Script Path: `Jenkinsfile`

2. **Update Jenkinsfile:**
   - Edit `Jenkinsfile` in repository
   - Update AWS account ID and region
   - Update EKS cluster name

3. **Run Pipeline:**
   - Click "Build Now"
   - Monitor pipeline execution

#### Step 3.4: Verify Deployment

```bash
# Check pods
kubectl get pods -n production

# Check services
kubectl get svc -n production

# Get application URL
kubectl get ingress -n production
```

**✅ Checkpoint:** Application accessible via ALB URL

**📚 Detailed Guide:** See [docs/APPLICATION-DEPLOYMENT.md](docs/APPLICATION-DEPLOYMENT.md)

---

## 🔍 What Gets Deployed

### Infrastructure Components

| Component | Details | Cost (Monthly) |
|-----------|---------|----------------|
| **VPC** | 8 subnets across 2 AZs | Free |
| **EKS Cluster** | Kubernetes 1.28 | $73 |
| **Worker Nodes** | 2-4 t3.medium instances | $60-120 |
| **RDS PostgreSQL** | db.t3.micro, Multi-AZ | $30 |
| **NAT Gateways** | 2 for high availability | $65 |
| **Application Load Balancer** | For ingress traffic | $23 |
| **Bastion Host** | t3.micro | $8 |
| **CloudWatch Logs** | EKS + VPC logs | ~$10 |
| **Jenkins Server** | t3.medium EC2 | $30 |
| **SonarQube Server** | t3.medium EC2 | $30 |
| **Total** | | **~$329-389/month** |

### Application Stack

- **Frontend:** React.js application
- **Backend:** Node.js REST API
- **Database:** MySQL (running in Kubernetes)
- **Ingress:** AWS Application Load Balancer
- **Auto-scaling:** Horizontal Pod Autoscaler (2-10 replicas)

### Security Features

✅ Private subnets for workloads  
✅ KMS encryption (EKS, RDS, Secrets)  
✅ Security groups with least privilege  
✅ IMDSv2 enforced  
✅ VPC Flow Logs enabled  
✅ Container image scanning (Trivy)  
✅ Code quality scanning (SonarQube)  
✅ Secrets management (Kubernetes Secrets)  

---

## 🔄 CI/CD Pipeline

The Jenkins pipeline automates:

1. **Code Checkout** - Pull latest code from Git
2. **Dependency Installation** - Install npm packages
3. **Code Quality Analysis** - SonarQube scanning
4. **Security Scanning** - Trivy filesystem scan
5. **Docker Build** - Build frontend and backend images
6. **Image Scanning** - Trivy container scan
7. **Push to ECR** - Upload images to AWS ECR
8. **Update Manifests** - Update K8s with new image tags
9. **Deploy to EKS** - Apply manifests to cluster
10. **Verification** - Check deployment status

**Pipeline Duration:** ~8-12 minutes

**📚 Pipeline Explanation:** See [docs/JENKINS-PIPELINE-EXPLAINED.md](docs/JENKINS-PIPELINE-EXPLAINED.md)

---

## 📊 Monitoring & Observability

### Install Monitoring Stack

```bash
cd monitoring
./install.sh
```

This installs:
- **Prometheus** - Metrics collection
- **Grafana** - Visualization dashboards
- **AlertManager** - Alert notifications

### Access Dashboards

```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit: http://localhost:3000 (admin / <password>)

# Get Grafana password
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**📚 Monitoring Guide:** See [docs/MONITORING.md](docs/MONITORING.md)

---

## 🛠️ Daily Operations

### View Application Logs

```bash
kubectl logs -f deployment/frontend -n production
kubectl logs -f deployment/backend -n production
```

### Scale Application

```bash
kubectl scale deployment frontend --replicas=5 -n production
```

### Update Application

```bash
# Trigger Jenkins pipeline or manually:
kubectl set image deployment/backend backend=<new-image> -n production
kubectl rollout status deployment/backend -n production
```

### Rollback Deployment

```bash
kubectl rollout undo deployment/backend -n production
```

### Access Bastion Host

```bash
ssh -i your-key.pem ec2-user@<bastion-ip>
```

---

## 🧹 Cleanup

### Delete Application

```bash
kubectl delete namespace production
```

### Destroy Infrastructure

```bash
cd terraform-resources/environments/production
terraform destroy

cd ../../bootstrap
terraform destroy
```

### Terminate EC2 Instances

```bash
# Jenkins and SonarQube servers
aws ec2 terminate-instances --instance-ids i-xxxxx i-yyyyy
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [terraform-resources/README.md](terraform-resources/README.md) | Complete Terraform guide |
| [docs/CICD-SETUP.md](docs/CICD-SETUP.md) | Jenkins & SonarQube setup |
| [docs/APPLICATION-DEPLOYMENT.md](docs/APPLICATION-DEPLOYMENT.md) | Application deployment guide |
| [docs/JENKINS-PIPELINE-EXPLAINED.md](docs/JENKINS-PIPELINE-EXPLAINED.md) | Pipeline deep dive |
| [docs/MONITORING.md](docs/MONITORING.md) | Monitoring setup and usage |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |

---

## 🎓 What You'll Learn

This project covers:

- ✅ Infrastructure as Code with Terraform
- ✅ AWS networking (VPC, subnets, security groups)
- ✅ Kubernetes orchestration on AWS EKS
- ✅ CI/CD pipeline design and implementation
- ✅ Container security scanning
- ✅ Code quality analysis
- ✅ Monitoring and observability
- ✅ Production best practices
- ✅ DevSecOps principles

---

## ⚠️ Important Notes

### Before Production Deployment

1. ✅ Change all default passwords
2. ✅ Restrict security group access to your IP
3. ✅ Enable AWS billing alerts
4. ✅ Review IAM permissions
5. ✅ Setup backup strategy
6. ✅ Configure SSL certificates
7. ✅ Setup custom domain
8. ✅ Enable WAF (Web Application Firewall)
9. ✅ Configure log retention policies
10. ✅ Document disaster recovery procedures

### Version Compatibility

This project is tested with:
- Terraform: 1.0+
- AWS Provider: 5.0+
- Kubernetes: 1.28
- Jenkins: 2.426+
- SonarQube: LTS Community Edition
- Node.js: 23.x
- Docker: 24.x

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📞 Support

For issues or questions:

1. Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review existing GitHub issues
3. Create a new issue with detailed information

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- AWS EKS Best Practices Guide
- Terraform AWS Provider Documentation
- Jenkins Pipeline Documentation
- Kubernetes Official Documentation

---

## 📈 Project Status

**Status:** Production-Ready ✅

**Last Updated:** February 2026

**Maintained By:** DevOps Team

---

**⭐ If you find this project helpful, please give it a star!**

**🔗 Connect:** [LinkedIn](https://linkedin.com/in/your-profile) | [GitHub](https://github.com/your-username)
