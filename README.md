# Production-Grade EKS Infrastructure

Complete production-ready AWS EKS infrastructure with Terraform, following AWS Well-Architected Framework principles.

## 📁 What's Inside

```
Production-base-project/
└── terraform-resources/
    ├── 📖 Documentation (5 files)
    │   ├── README.md                    # Complete setup guide
    │   ├── QUICKSTART.md                # Quick reference
    │   ├── STRUCTURE.md                 # Project structure
    │   ├── DEPLOYMENT-CHECKLIST.md      # Deployment checklist
    │   └── PROJECT-SUMMARY.md           # This summary
    │
    ├── 🔧 Bootstrap (Remote Backend)
    │   ├── main.tf                      # S3 + DynamoDB
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    │
    ├── 📦 Modules (7 modules, 21 files)
    │   ├── vpc/                         # VPC with 8 subnets
    │   ├── security-groups/             # 5 security groups
    │   ├── eks/                         # EKS cluster + node groups
    │   ├── bastion/                     # Bastion host
    │   ├── rds/                         # PostgreSQL database
    │   ├── secrets/                     # Secrets Manager
    │   └── iam/                         # IAM roles (placeholder)
    │
    └── 🌍 Environments
        └── production/
            ├── main.tf                  # Module composition
            ├── providers.tf             # AWS provider + backend
            ├── variables.tf             # All variables
            ├── outputs.tf               # Important outputs
            └── terraform.tfvars.example # Example configuration
```

**Total Files Created:** 31 files

## 🎯 Infrastructure Overview

### What Gets Deployed

- **1 VPC** with 8 subnets across 2 availability zones
- **1 EKS Cluster** (Kubernetes 1.28) with 2 node groups
- **4-10 EC2 instances** (EKS worker nodes, auto-scaled)
- **1 RDS PostgreSQL** instance (Multi-AZ, encrypted)
- **1 Bastion host** for secure access
- **2 NAT Gateways** for high availability
- **5 Security Groups** with least privilege rules
- **3 KMS Keys** for encryption
- **1 Secrets Manager** secret for database credentials
- **CloudWatch Logs** and monitoring

### Estimated Cost

**~$414/month** (us-east-1)

Can be reduced to ~$200/month for dev environments.

## 🚀 Quick Start

### Prerequisites

```bash
# Install required tools
terraform --version  # >= 1.0
aws --version        # >= 2.0
kubectl version      # >= 1.28

# Configure AWS
aws configure

# Create SSH key
aws ec2 create-key-pair --key-name prod-eks-key \
  --query 'KeyMaterial' --output text > ~/.ssh/prod-eks-key.pem
chmod 400 ~/.ssh/prod-eks-key.pem
```

### Deploy in 3 Steps

```bash
# 1. Setup remote backend (5 min)
cd terraform-resources/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 2. Deploy infrastructure (25 min)
cd ../environments/production
cp terraform.tfvars.example terraform.tfvars
# IMPORTANT: Edit terraform.tfvars (change key_name, IPs, password)
terraform init && terraform apply

# 3. Configure kubectl (2 min)
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1
kubectl get nodes
```

## 📚 Documentation

Start here based on your needs:

1. **First time deploying?** → Read `terraform-resources/README.md`
2. **Need quick commands?** → Check `terraform-resources/QUICKSTART.md`
3. **Want to understand structure?** → See `terraform-resources/STRUCTURE.md`
4. **Ready to deploy?** → Follow `terraform-resources/DEPLOYMENT-CHECKLIST.md`
5. **Overview of features?** → Read `terraform-resources/PROJECT-SUMMARY.md`

## ✨ Key Features

### Production Best Practices

✅ **High Availability** - Multi-AZ deployment  
✅ **Security** - Private subnets, encryption, secrets management  
✅ **Scalability** - Auto-scaling node groups (2-10 nodes)  
✅ **Monitoring** - CloudWatch logs and metrics  
✅ **Disaster Recovery** - Automated backups, Multi-AZ RDS  
✅ **Cost Optimized** - Right-sized instances, configurable  

### Security Features

- All workloads in private subnets
- KMS encryption for EKS, RDS, Secrets Manager
- Security groups with least privilege
- VPC Flow Logs enabled
- IMDSv2 enforced on EC2
- Bastion host for secure access
- IAM roles with minimal permissions

### Monitoring & Logging

- EKS control plane logs → CloudWatch
- VPC Flow Logs → CloudWatch
- RDS Enhanced Monitoring
- Performance Insights for RDS
- CloudWatch metrics for all resources

## 🎓 What You'll Learn

This infrastructure teaches you:

1. **AWS Networking** - VPC, subnets, NAT, security groups
2. **Kubernetes on AWS** - EKS, node groups, IRSA
3. **Infrastructure as Code** - Terraform modules, state management
4. **Security Best Practices** - Encryption, secrets, IAM
5. **Production Operations** - Monitoring, DR, cost optimization

## 🔄 Next Steps After Deployment

### Immediate

1. Install AWS Load Balancer Controller
2. Install Metrics Server
3. **Install Monitoring Stack (Prometheus + Grafana)**
4. Test bastion host access
5. Verify RDS connectivity

### This Week

1. Deploy your application to EKS
2. Configure Ingress for external access
3. **Set up monitoring dashboards**
4. **Configure alerting (Slack/Email)**
5. Set up CI/CD pipeline

### This Month

1. Implement GitOps (ArgoCD)
2. Add DevSecOps tools (Trivy, SonarQube, OWASP)
3. **Set up log aggregation (ELK/Loki)**
4. Conduct security audit
5. Optimize costs

## 🛠️ Customization

All configurable via `terraform.tfvars`:

- Instance types and sizes
- Node group min/max counts
- Database size and configuration
- Backup retention periods
- Network CIDR blocks
- Availability zones
- Enable/disable features

## ⚠️ Important Security Notes

Before deploying to production:

1. ✅ Change `db_master_password` to a strong password
2. ✅ Change `allowed_ssh_cidrs` to your IP (not 0.0.0.0/0)
3. ✅ Change `public_access_cidrs` to your IP (not 0.0.0.0/0)
4. ✅ Update `key_name` to your actual EC2 key pair
5. ✅ Never commit `terraform.tfvars` to Git
6. ✅ Never commit SSH private keys
7. ✅ Set up AWS billing alerts

## 🐛 Troubleshooting

Common issues and solutions are documented in:
- `terraform-resources/README.md` (Troubleshooting section)
- `terraform-resources/QUICKSTART.md` (Quick fixes)

Quick debug commands:

```bash
# Check EKS cluster
kubectl get nodes
kubectl get pods -A

# SSH to bastion
ssh -i ~/.ssh/prod-eks-key.pem ec2-user@<bastion-ip>

# View logs
kubectl logs -f <pod-name>
aws logs tail /aws/eks/production-eks-infra-eks/cluster --follow

# Check Terraform state
terraform state list
terraform show
```

## 💰 Cost Management

Monitor costs:

```bash
# Check running resources
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
aws rds describe-db-instances
aws ec2 describe-nat-gateways

# Use AWS Cost Explorer in Console
# Set up billing alerts
```

Reduce costs:
- Use Spot instances for dev/staging
- Single NAT Gateway for non-production
- Smaller instance types
- Reduce backup retention
- Auto-shutdown for dev environments

## 🗑️ Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources first
kubectl delete all --all -A

# Destroy infrastructure
cd terraform-resources/environments/production
terraform destroy

# Destroy backend (optional)
cd ../../bootstrap
terraform destroy
```

## 📞 Support & Resources

- **AWS EKS Best Practices**: https://aws.github.io/aws-eks-best-practices/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Kubernetes Docs**: https://kubernetes.io/docs/home/

## 📄 License

This infrastructure code is provided as-is for educational and production use.

---

## 🎉 Ready to Deploy?

1. Read `terraform-resources/README.md` for detailed instructions
2. Follow `terraform-resources/DEPLOYMENT-CHECKLIST.md` step-by-step
3. Use `terraform-resources/QUICKSTART.md` for daily operations

**Questions?** Check the troubleshooting sections in the documentation!

---

**Created:** February 2026  
**Terraform:** >= 1.0  
**AWS Provider:** ~> 5.0  
**Kubernetes:** 1.28  
