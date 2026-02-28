# Production EKS Infrastructure with Terraform

Production-grade AWS EKS infrastructure following best practices with multi-AZ deployment, security hardening, and comprehensive monitoring.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Step-by-Step Setup](#step-by-step-setup)
- [Post-Deployment Configuration](#post-deployment-configuration)
- [Debugging Guide](#debugging-guide)
- [Cost Optimization](#cost-optimization)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Internet (0.0.0.0/0)                        │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Internet Gateway │
                    └────────┬────────┘
                             │
┌────────────────────────────┼────────────────────────────────────────┐
│  VPC: 10.0.0.0/16          │                                        │
│                            │                                        │
│  ┌─────────────────────────▼──────────────────────────────────┐    │
│  │  PUBLIC SUBNETS (2 AZs)                                    │    │
│  │  10.0.1.0/24 | 10.0.2.0/24                                │    │
│  ├────────────────────────────────────────────────────────────┤    │
│  │  • Bastion Host (kubectl access)                          │    │
│  │  • NAT Gateways (2 for HA)                                │    │
│  │  • Application Load Balancer                              │    │
│  └────────────────────────┬───────────────────────────────────┘    │
│                           │                                         │
│  ┌────────────────────────▼───────────────────────────────────┐    │
│  │  PRIVATE FRONTEND SUBNETS (EKS Worker Nodes)              │    │
│  │  10.0.11.0/24 | 10.0.12.0/24                             │    │
│  ├───────────────────────────────────────────────────────────┤    │
│  │  • EKS Frontend Node Group (2-4 nodes)                    │    │
│  │  • Frontend Pods (Auto-scaled)                            │    │
│  └────────────────────────┬───────────────────────────────────┘    │
│                           │                                         │
│  ┌────────────────────────▼───────────────────────────────────┐    │
│  │  PRIVATE BACKEND SUBNETS (EKS Worker Nodes)               │    │
│  │  10.0.21.0/24 | 10.0.22.0/24                             │    │
│  ├───────────────────────────────────────────────────────────┤    │
│  │  • EKS Backend Node Group (2-6 nodes)                     │    │
│  │  • Backend Pods (Auto-scaled)                             │    │
│  └────────────────────────┬───────────────────────────────────┘    │
│                           │                                         │
│  ┌────────────────────────▼───────────────────────────────────┐    │
│  │  PRIVATE DATABASE SUBNETS (Isolated)                      │    │
│  │  10.0.31.0/24 | 10.0.32.0/24                             │    │
│  ├───────────────────────────────────────────────────────────┤    │
│  │  • RDS PostgreSQL 15 (Multi-AZ)                           │    │
│  │  • Encrypted storage (KMS)                                │    │
│  │  • Automated backups (30 days)                            │    │
│  └───────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  AWS Services (Outside VPC)                                         │
├─────────────────────────────────────────────────────────────────────┤
│  • EKS Control Plane (AWS Managed)                                  │
│  • Secrets Manager (Database credentials)                           │
│  • CloudWatch (Logs & Metrics)                                      │
│  • KMS (Encryption keys)                                            │
│  • ECR (Container images)                                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Features

✅ **High Availability**: Multi-AZ deployment across 2 availability zones  
✅ **Security**: Private subnets, security groups, KMS encryption, secrets management  
✅ **Scalability**: EKS auto-scaling for frontend (2-4) and backend (2-6) nodes  
✅ **Monitoring**: CloudWatch logs, VPC Flow Logs, RDS Enhanced Monitoring  
✅ **Disaster Recovery**: Automated RDS backups (30 days), Multi-AZ database  
✅ **Cost Optimized**: Right-sized instances, gp3 storage, configurable NAT gateways  

---

## 📦 Prerequisites

### Required Tools

```bash
# Terraform
terraform --version  # >= 1.0

# AWS CLI
aws --version  # >= 2.0

# kubectl
kubectl version --client  # >= 1.28

# Optional but recommended
helm version  # >= 3.0
```

### AWS Requirements

1. **AWS Account** with appropriate permissions
2. **IAM User/Role** with these policies:
   - `AdministratorAccess` (for initial setup)
   - Or custom policy with: VPC, EKS, EC2, RDS, S3, DynamoDB, IAM, KMS, Secrets Manager permissions

3. **AWS CLI configured**:
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
```

4. **EC2 Key Pair** (for bastion host):
```bash
aws ec2 create-key-pair --key-name prod-eks-key --query 'KeyMaterial' --output text > ~/.ssh/prod-eks-key.pem
chmod 400 ~/.ssh/prod-eks-key.pem
```

---

## 🚀 Quick Start

```bash
# 1. Clone/Navigate to project
cd Production-base-project/terraform-resources

# 2. Setup remote backend
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply

# 3. Deploy infrastructure
cd ../environments/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (update key_name, allowed_ssh_cidrs, db_password)
terraform init
terraform apply

# 4. Configure kubectl
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1

# 5. Verify
kubectl get nodes
```

---

## 📝 Step-by-Step Setup

### Step 1: Setup Remote Backend (S3 + DynamoDB)

**Why?** Store Terraform state remotely for team collaboration and state locking.

```bash
cd bootstrap

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region   = "us-east-1"
project_name = "prod-eks-infra"
environment  = "production"
```

```bash
# Initialize and apply
terraform init
terraform apply

# Note the outputs - you'll need these
terraform output
```

**Expected Output:**
```
s3_bucket_name = "prod-eks-infra-terraform-state-production"
dynamodb_table_name = "prod-eks-infra-terraform-locks-production"
```

### Step 2: Configure Backend in Main Terraform

```bash
cd ../environments/production
```

Edit `providers.tf` and **uncomment** the backend block:

```hcl
backend "s3" {
  bucket         = "prod-eks-infra-terraform-state-production"  # From Step 1
  key            = "terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "prod-eks-infra-terraform-locks-production"  # From Step 1
  encrypt        = true
}
```

### Step 3: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` - **CRITICAL CHANGES**:

```hcl
# 1. Change SSH key name
key_name = "prod-eks-key"  # Your actual key pair name

# 2. Restrict SSH access (IMPORTANT for production)
allowed_ssh_cidrs = ["YOUR_IP_ADDRESS/32"]  # Get your IP: curl ifconfig.me

# 3. Restrict EKS API access (IMPORTANT for production)
public_access_cidrs = ["YOUR_IP_ADDRESS/32"]

# 4. Change database password (REQUIRED)
db_master_password = "YourStrongPassword123!@#"  # Use strong password

# 5. Optional: Adjust instance sizes for cost
frontend_instance_types = ["t3.small"]  # Smaller for dev
backend_instance_types  = ["t3.small"]
db_instance_class       = "db.t3.small"
```

### Step 4: Initialize Terraform

```bash
terraform init
```

**Expected Output:**
```
Initializing modules...
Initializing the backend...
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

### Step 5: Plan Infrastructure

```bash
terraform plan -out=tfplan
```

**Review the plan carefully:**
- ~60-70 resources will be created
- Check costs (use AWS Pricing Calculator)
- Verify CIDR blocks don't conflict with existing networks

### Step 6: Apply Infrastructure

```bash
terraform apply tfplan
```

**Duration:** ~20-25 minutes (EKS cluster takes longest)

**Expected Output:**
```
Apply complete! Resources: 67 added, 0 changed, 0 destroyed.

Outputs:
eks_cluster_name = "production-eks-infra-eks"
bastion_public_ip = "54.123.45.67"
configure_kubectl = "aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1"
```

### Step 7: Configure kubectl

```bash
# Configure kubectl to access EKS cluster
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1

# Verify connection
kubectl get nodes
```

**Expected Output:**
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-11-123.ec2.internal   Ready    <none>   5m    v1.28.x
ip-10-0-12-234.ec2.internal   Ready    <none>   5m    v1.28.x
ip-10-0-21-123.ec2.internal   Ready    <none>   5m    v1.28.x
ip-10-0-22-234.ec2.internal   Ready    <none>   5m    v1.28.x
```

---

## ⚙️ Post-Deployment Configuration

### 1. Install AWS Load Balancer Controller

**Required for ALB Ingress to work with EKS.**

```bash
# Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Get OIDC provider
OIDC_PROVIDER=$(terraform output -raw eks_oidc_provider_arn | sed 's/.*\///')

# Create IAM role for service account
eksctl create iamserviceaccount \
  --cluster=production-eks-infra-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# Install controller using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-eks-infra-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### 2. Install External Secrets Operator (Optional)

**Sync secrets from AWS Secrets Manager to Kubernetes.**

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n kube-system

# Create SecretStore
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: default
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: default
EOF
```

### 3. Install Metrics Server (For HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl get deployment metrics-server -n kube-system
```

### 4. Install Cluster Autoscaler

```bash
# Create IAM policy
cat <<EOF > cluster-autoscaler-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF

aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://cluster-autoscaler-policy.json

# Deploy autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit deployment to add cluster name
kubectl -n kube-system edit deployment cluster-autoscaler
# Add: --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/production-eks-infra-eks
```

---

## 🐛 Debugging Guide

### Access Bastion Host

```bash
# Get bastion IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# SSH into bastion
ssh -i ~/.ssh/prod-eks-key.pem ec2-user@$BASTION_IP

# Once inside bastion, kubectl is pre-configured
kubectl get nodes
kubectl get pods -A
```

### Common kubectl Commands

```bash
# View all pods
kubectl get pods -A

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Follow logs
kubectl logs -f <pod-name> -n <namespace>

# Describe pod (see events)
kubectl describe pod <pod-name> -n <namespace>

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Port forward to local machine
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>

# View events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Check EKS Cluster Health

```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# Check control plane logs (from AWS CLI)
aws eks describe-cluster --name production-eks-infra-eks --query 'cluster.logging'
```

### Check RDS Connection

```bash
# From bastion host
PGPASSWORD='YourPassword' psql -h <rds-endpoint> -U dbadmin -d appdb

# Test connection
\conninfo
\l  # List databases
\q  # Quit
```

### View CloudWatch Logs

```bash
# EKS control plane logs
aws logs tail /aws/eks/production-eks-infra-eks/cluster --follow

# VPC Flow Logs
aws logs tail /aws/vpc/production-flow-logs --follow
```

---

## 💰 Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| EKS Control Plane | 1 cluster | $73 |
| EC2 Worker Nodes | 4x t3.medium (on-demand) | ~$120 |
| NAT Gateways | 2x NAT Gateway | ~$65 |
| RDS PostgreSQL | db.t3.medium Multi-AZ | ~$120 |
| EBS Volumes | 200GB gp3 | ~$16 |
| Data Transfer | Moderate | ~$20 |
| **Total** | | **~$414/month** |

### Cost Reduction Strategies

1. **Use Spot Instances for non-production**:
```hcl
capacity_type = "SPOT"  # In terraform.tfvars
```
Savings: ~70% on EC2 costs

2. **Single NAT Gateway** (dev/staging only):
```hcl
enable_nat_gateway = true
# Modify vpc module to use single NAT
```
Savings: ~$32/month

3. **Smaller RDS instance**:
```hcl
db_instance_class = "db.t3.small"
db_multi_az = false  # Dev only
```
Savings: ~$60/month

4. **Reduce backup retention**:
```hcl
db_backup_retention_period = 7  # Instead of 30
```
Savings: ~$5/month

5. **Use Fargate for some workloads** (pay per pod):
- No EC2 management
- Pay only when pods run

---

## 🔒 Security Best Practices

### Implemented Security Features

✅ **Network Security**
- Private subnets for all workloads
- Security groups with least privilege
- VPC Flow Logs enabled
- No direct internet access to databases

✅ **Encryption**
- EKS secrets encrypted with KMS
- RDS storage encrypted with KMS
- Secrets Manager for credentials
- EBS volumes encrypted

✅ **Access Control**
- IAM roles for service accounts (IRSA)
- Bastion host for SSH access only
- EKS API endpoint access restricted
- SSM Session Manager enabled

✅ **Monitoring**
- CloudWatch logs for EKS control plane
- RDS Enhanced Monitoring
- VPC Flow Logs
- CloudTrail (enable separately)

### Additional Hardening (Recommended)

1. **Enable AWS GuardDuty**:
```bash
aws guardduty create-detector --enable
```

2. **Enable AWS Config**:
```bash
aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT:role/config-role
```

3. **Implement Pod Security Standards**:
```bash
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
```

4. **Install Falco** (Runtime security):
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace
```

5. **Enable Network Policies**:
```bash
# Install Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

---

## 🔧 Troubleshooting

### Issue: Terraform apply fails with "InvalidParameterException"

**Symptom:**
```
Error: error creating EKS Cluster: InvalidParameterException: The following supplied subnets do not exist
```

**Solution:**
1. Check VPC and subnet creation succeeded
2. Verify CIDR blocks don't overlap
3. Run `terraform plan` again to see dependencies

### Issue: kubectl cannot connect to cluster

**Symptom:**
```
error: You must be logged in to the server (Unauthorized)
```

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1

# Verify AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws eks describe-cluster --name production-eks-infra-eks
```

### Issue: Nodes not joining cluster

**Symptom:**
```
kubectl get nodes
No resources found
```

**Solution:**
1. Check node group status:
```bash
aws eks describe-nodegroup --cluster-name production-eks-infra-eks --nodegroup-name production-eks-infra-eks-frontend-ng
```

2. Check CloudWatch logs:
```bash
aws logs tail /aws/eks/production-eks-infra-eks/cluster --follow
```

3. Verify security groups allow communication

### Issue: Pods stuck in Pending state

**Symptom:**
```
kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
app-1   0/1     Pending   0          5m
```

**Solution:**
```bash
# Check pod events
kubectl describe pod app-1

# Common causes:
# 1. Insufficient resources
kubectl top nodes

# 2. Node selector mismatch
kubectl get nodes --show-labels

# 3. PVC not bound
kubectl get pvc
```

### Issue: Cannot connect to RDS from pods

**Symptom:**
```
Error: could not connect to server: Connection timed out
```

**Solution:**
1. Check security group rules:
```bash
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

2. Verify RDS endpoint:
```bash
terraform output rds_endpoint
```

3. Test from bastion:
```bash
ssh bastion
PGPASSWORD='password' psql -h <rds-endpoint> -U dbadmin -d appdb
```

4. Check secrets in Kubernetes:
```bash
kubectl get secret db-credentials -o yaml
```

### Issue: High costs

**Solution:**
1. Check running resources:
```bash
# EC2 instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[InstanceId,InstanceType]'

# NAT Gateways
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"

# Load Balancers
aws elbv2 describe-load-balancers
```

2. Review Cost Explorer in AWS Console

3. Enable AWS Cost Anomaly Detection

### Issue: Terraform state locked

**Symptom:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# List locks
aws dynamodb scan --table-name prod-eks-infra-terraform-locks-production

# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

---

## 📚 Additional Resources

### Documentation
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)

### Tools
- [k9s](https://k9scli.io/) - Kubernetes CLI UI (pre-installed on bastion)
- [kubectx/kubens](https://github.com/ahmetb/kubectx) - Switch contexts/namespaces
- [stern](https://github.com/stern/stern) - Multi-pod log tailing

### Monitoring & Observability
- [Prometheus + Grafana](https://github.com/prometheus-operator/kube-prometheus)
- [AWS Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)
- [Datadog](https://www.datadoghq.com/), [New Relic](https://newrelic.com/)

---

## 🗑️ Cleanup

**WARNING:** This will destroy all resources and data!

```bash
# 1. Delete Kubernetes resources first
kubectl delete all --all -n default

# 2. Delete AWS Load Balancer Controller
helm uninstall aws-load-balancer-controller -n kube-system

# 3. Destroy Terraform infrastructure
cd environments/production
terraform destroy

# 4. Destroy backend (optional)
cd ../../bootstrap
terraform destroy
```

---

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review CloudWatch logs
3. Check AWS Service Health Dashboard
4. Consult AWS Support (if you have a support plan)

---

## 📄 License

This infrastructure code is provided as-is for educational and production use.

---

**Next Steps:** Once infrastructure is deployed, add your application code and Kubernetes manifests to deploy your workloads!
