# Project Structure

```
Production-base-project/
└── terraform-resources/
    ├── README.md                          # Comprehensive setup guide
    ├── QUICKSTART.md                      # Quick reference commands
    ├── .gitignore                         # Git ignore rules
    │
    ├── bootstrap/                         # Remote backend setup (S3 + DynamoDB)
    │   ├── main.tf                        # S3 bucket and DynamoDB table
    │   ├── variables.tf                   # Bootstrap variables
    │   ├── outputs.tf                     # Backend configuration outputs
    │   └── terraform.tfvars.example       # Example configuration
    │
    ├── modules/                           # Reusable Terraform modules
    │   ├── vpc/                           # VPC with public/private subnets
    │   │   ├── main.tf                    # VPC, subnets, NAT, IGW, route tables
    │   │   ├── variables.tf               # VPC configuration variables
    │   │   └── outputs.tf                 # VPC and subnet IDs
    │   │
    │   ├── security-groups/               # Security groups for all resources
    │   │   ├── main.tf                    # ALB, EKS, nodes, bastion, RDS SGs
    │   │   ├── variables.tf               # Security group variables
    │   │   └── outputs.tf                 # Security group IDs
    │   │
    │   ├── eks/                           # EKS cluster and node groups
    │   │   ├── main.tf                    # Cluster, node groups, OIDC, addons
    │   │   ├── variables.tf               # EKS configuration variables
    │   │   └── outputs.tf                 # Cluster endpoint, OIDC provider
    │   │
    │   ├── bastion/                       # Bastion host for SSH/kubectl access
    │   │   ├── main.tf                    # EC2 instance with IAM role
    │   │   ├── user_data.sh               # Bootstrap script (kubectl, helm, k9s)
    │   │   ├── variables.tf               # Bastion configuration
    │   │   └── outputs.tf                 # Bastion IP addresses
    │   │
    │   ├── rds/                           # PostgreSQL RDS instance
    │   │   ├── main.tf                    # RDS instance, KMS, monitoring
    │   │   ├── variables.tf               # Database configuration
    │   │   └── outputs.tf                 # Database endpoint
    │   │
    │   └── secrets/                       # AWS Secrets Manager
    │       ├── main.tf                    # Secret for database credentials
    │       ├── variables.tf               # Secret configuration
    │       └── outputs.tf                 # Secret ARN
    │
    └── environments/
        └── production/                    # Production environment
            ├── providers.tf               # AWS provider and backend config
            ├── main.tf                    # Module composition
            ├── variables.tf               # All input variables
            ├── outputs.tf                 # Important outputs
            └── terraform.tfvars.example   # Example values (copy to .tfvars)
```

## Module Dependencies

```
main.tf (production)
├── vpc
├── security-groups (depends on: vpc)
├── eks (depends on: vpc, security-groups)
├── bastion (depends on: vpc, security-groups, eks)
├── rds (depends on: vpc, security-groups)
└── secrets (depends on: rds)
```

## Key Files to Modify

### Before Deployment

1. **bootstrap/terraform.tfvars** (copy from .example)
   - Set AWS region
   - Set project name

2. **environments/production/terraform.tfvars** (copy from .example)
   - ⚠️ **REQUIRED**: Change `key_name` to your EC2 key pair
   - ⚠️ **REQUIRED**: Change `db_master_password` to strong password
   - ⚠️ **REQUIRED**: Change `allowed_ssh_cidrs` to your IP
   - ⚠️ **REQUIRED**: Change `public_access_cidrs` to your IP
   - Optional: Adjust instance sizes, node counts

3. **environments/production/providers.tf**
   - Uncomment backend block after running bootstrap
   - Update bucket and table names from bootstrap output

### After Deployment

- Add your application Kubernetes manifests
- Configure CI/CD pipelines
- Set up monitoring and alerting

## Resource Naming Convention

All resources follow this pattern:
```
{environment}-{resource-type}-{identifier}

Examples:
- production-eks-infra-eks (EKS cluster)
- production-bastion-host (EC2 instance)
- production-db-subnet-group (RDS subnet group)
```

## Tags Applied to All Resources

```hcl
{
  Environment = "production"
  Project     = "eks-infra"
  ManagedBy   = "Terraform"
}
```

## State Management

- **Local state**: bootstrap/ (initial setup only)
- **Remote state**: environments/production/ (stored in S3)
- **State locking**: DynamoDB table prevents concurrent modifications
- **Encryption**: State files encrypted at rest in S3

## Security Features

✅ All sensitive outputs marked as `sensitive = true`  
✅ Secrets stored in AWS Secrets Manager (not in code)  
✅ KMS encryption for EKS, RDS, Secrets Manager  
✅ Private subnets for all workloads  
✅ Security groups with least privilege  
✅ VPC Flow Logs enabled  
✅ CloudWatch logging enabled  

## Next Steps

1. Follow README.md for step-by-step deployment
2. Use QUICKSTART.md for daily operations
3. Add your application code in a separate directory
4. Create Kubernetes manifests for your workloads
5. Set up CI/CD pipeline (GitHub Actions, GitLab CI, etc.)
