# Production EKS Infrastructure - Quick Reference

## 🚀 Quick Commands

### Initial Setup
```bash
# 1. Setup backend
cd bootstrap && terraform init && terraform apply

# 2. Deploy infrastructure  
cd ../environments/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (key_name, IPs, password)
terraform init && terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1
kubectl get nodes
```

### Daily Operations
```bash
# View all resources
kubectl get all -A

# Check node health
kubectl top nodes

# View logs
kubectl logs -f <pod-name> -n <namespace>

# SSH to bastion
ssh -i ~/.ssh/prod-eks-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# Update infrastructure
terraform plan
terraform apply
```

## 🔍 Health Check Checklist

- [ ] All nodes are Ready: `kubectl get nodes`
- [ ] System pods running: `kubectl get pods -n kube-system`
- [ ] RDS accessible: Test from bastion
- [ ] Secrets available: `kubectl get secrets`
- [ ] Load balancer controller running
- [ ] Metrics server working: `kubectl top nodes`

## 📊 Resource Inventory

| Resource Type | Count | Purpose |
|--------------|-------|---------|
| VPC | 1 | Network isolation |
| Subnets | 8 | 2 public, 6 private (2 frontend, 2 backend, 2 database) |
| NAT Gateways | 2 | Internet access for private subnets |
| EKS Cluster | 1 | Kubernetes control plane |
| Node Groups | 2 | Frontend (2-4 nodes), Backend (2-6 nodes) |
| RDS Instance | 1 | PostgreSQL 15 Multi-AZ |
| Bastion Host | 1 | SSH/kubectl access |
| Security Groups | 5 | ALB, EKS cluster, nodes, bastion, RDS |
| KMS Keys | 3 | EKS, RDS, Secrets Manager |
| Secrets | 1 | Database credentials |

## 🔐 Security Checklist

- [ ] SSH access restricted to your IP
- [ ] EKS API access restricted to your IP
- [ ] Database password changed from default
- [ ] All encryption enabled (EKS, RDS, EBS)
- [ ] VPC Flow Logs enabled
- [ ] CloudWatch logging enabled
- [ ] IAM roles follow least privilege
- [ ] No public access to databases
- [ ] Secrets stored in AWS Secrets Manager

## 💰 Cost Monitoring

```bash
# Check running EC2 instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name]' --output table

# Check NAT Gateway costs
aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --output table

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,MultiAZ]' --output table
```

## 🐛 Quick Troubleshooting

### Nodes not appearing
```bash
aws eks describe-nodegroup --cluster-name production-eks-infra-eks \
  --nodegroup-name production-eks-infra-eks-frontend-ng
```

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### Cannot connect to RDS
```bash
# From bastion
PGPASSWORD='password' psql -h <endpoint> -U dbadmin -d appdb
```

### Terraform state locked
```bash
terraform force-unlock <LOCK_ID>
```

## 📞 Emergency Contacts

- AWS Support: https://console.aws.amazon.com/support
- EKS Documentation: https://docs.aws.amazon.com/eks
- Terraform Registry: https://registry.terraform.io

## 🔄 Update Procedure

1. Test changes in dev environment first
2. Create backup: `terraform state pull > backup.tfstate`
3. Plan changes: `terraform plan -out=tfplan`
4. Review plan carefully
5. Apply during maintenance window: `terraform apply tfplan`
6. Verify: `kubectl get nodes` and check application health

## 📈 Scaling

### Scale node groups
```bash
# Update terraform.tfvars
frontend_desired_size = 4
backend_desired_size = 4

# Apply
terraform apply
```

### Scale pods (HPA)
```bash
kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10
```

## 🗑️ Cleanup

```bash
# Delete all Kubernetes resources
kubectl delete all --all -A

# Destroy infrastructure
terraform destroy

# Destroy backend
cd ../../bootstrap && terraform destroy
```
