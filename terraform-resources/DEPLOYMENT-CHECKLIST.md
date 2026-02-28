# Production Deployment Checklist

Use this checklist to ensure a smooth deployment.

## ☐ Pre-Deployment (Before Running Terraform)

### AWS Account Setup
- [ ] AWS account created and accessible
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] IAM user/role has sufficient permissions
- [ ] Billing alerts configured in AWS Console
- [ ] Cost budget set (recommended: $500/month for production)

### Local Environment
- [ ] Terraform installed (>= 1.0)
- [ ] kubectl installed (>= 1.28)
- [ ] helm installed (>= 3.0)
- [ ] Git repository initialized (optional but recommended)

### SSH Key Pair
- [ ] EC2 key pair created: `aws ec2 create-key-pair --key-name prod-eks-key`
- [ ] Private key saved securely: `~/.ssh/prod-eks-key.pem`
- [ ] Correct permissions set: `chmod 400 ~/.ssh/prod-eks-key.pem`

### Configuration Files
- [ ] `bootstrap/terraform.tfvars` created from example
- [ ] `environments/production/terraform.tfvars` created from example
- [ ] **CRITICAL**: `key_name` updated in terraform.tfvars
- [ ] **CRITICAL**: `db_master_password` changed to strong password
- [ ] **CRITICAL**: `allowed_ssh_cidrs` set to your IP (not 0.0.0.0/0)
- [ ] **CRITICAL**: `public_access_cidrs` set to your IP (not 0.0.0.0/0)
- [ ] Optional: Instance sizes adjusted for your needs

### Network Planning
- [ ] VPC CIDR (10.0.0.0/16) doesn't conflict with existing networks
- [ ] Subnet CIDRs reviewed and approved
- [ ] Availability zones confirmed available in your region

---

## ☐ Bootstrap Deployment (Remote Backend)

### Initialize Bootstrap
- [ ] Navigate to bootstrap directory: `cd bootstrap`
- [ ] Run `terraform init`
- [ ] Review plan: `terraform plan`
- [ ] Apply: `terraform apply`
- [ ] Note S3 bucket name from output
- [ ] Note DynamoDB table name from output

### Configure Backend
- [ ] Edit `environments/production/providers.tf`
- [ ] Uncomment backend "s3" block
- [ ] Update bucket name from bootstrap output
- [ ] Update dynamodb_table name from bootstrap output
- [ ] Save file

---

## ☐ Infrastructure Deployment

### Initialize Production Environment
- [ ] Navigate to production: `cd ../environments/production`
- [ ] Run `terraform init`
- [ ] Verify backend initialized successfully
- [ ] Review plan: `terraform plan -out=tfplan`
- [ ] Verify ~60-70 resources will be created
- [ ] Check estimated costs (use AWS Pricing Calculator)

### Deploy Infrastructure
- [ ] Apply plan: `terraform apply tfplan`
- [ ] Wait ~20-25 minutes for completion
- [ ] Verify no errors in output
- [ ] Save outputs: `terraform output > outputs.txt`

### Verify Deployment
- [ ] EKS cluster created: Check AWS Console
- [ ] Node groups active: Check AWS Console
- [ ] RDS instance available: Check AWS Console
- [ ] Bastion host running: Check AWS Console

---

## ☐ Post-Deployment Configuration

### Configure kubectl
- [ ] Run: `aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1`
- [ ] Test connection: `kubectl get nodes`
- [ ] Verify all nodes are Ready
- [ ] Check system pods: `kubectl get pods -n kube-system`

### Install AWS Load Balancer Controller
- [ ] Download IAM policy
- [ ] Create IAM policy in AWS
- [ ] Create IAM service account
- [ ] Install via Helm
- [ ] Verify deployment: `kubectl get deployment -n kube-system aws-load-balancer-controller`

### Install Metrics Server
- [ ] Apply manifest: `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
- [ ] Verify: `kubectl get deployment metrics-server -n kube-system`
- [ ] Test: `kubectl top nodes`

### Optional: Install External Secrets Operator
- [ ] Add Helm repo
- [ ] Install chart
- [ ] Create SecretStore
- [ ] Test secret sync

### Optional: Install Cluster Autoscaler
- [ ] Create IAM policy
- [ ] Deploy autoscaler
- [ ] Configure for your cluster
- [ ] Verify deployment

---

## ☐ Security Verification

### Network Security
- [ ] Bastion host only accessible from your IP
- [ ] EKS API only accessible from your IP (or VPN)
- [ ] RDS not publicly accessible
- [ ] Security groups follow least privilege

### Encryption
- [ ] EKS secrets encrypted (check cluster config)
- [ ] RDS storage encrypted (check RDS config)
- [ ] EBS volumes encrypted (check EC2 volumes)
- [ ] Secrets Manager using KMS (check secret config)

### Access Control
- [ ] IAM roles properly configured
- [ ] No hardcoded credentials in code
- [ ] Database password stored in Secrets Manager
- [ ] SSH key not committed to Git

### Monitoring
- [ ] CloudWatch logs enabled for EKS
- [ ] VPC Flow Logs enabled
- [ ] RDS Enhanced Monitoring enabled
- [ ] CloudWatch alarms configured (optional)

---

## ☐ Application Deployment

### Prepare Application
- [ ] Container images built
- [ ] Images pushed to ECR
- [ ] Kubernetes manifests created
- [ ] ConfigMaps/Secrets defined
- [ ] Ingress/Service configured

### Deploy Application
- [ ] Create namespace: `kubectl create namespace app`
- [ ] Apply manifests: `kubectl apply -f k8s/`
- [ ] Check pod status: `kubectl get pods -n app`
- [ ] Check logs: `kubectl logs -f <pod-name> -n app`
- [ ] Verify application accessible

### Configure Ingress
- [ ] Create Ingress resource
- [ ] Verify ALB created in AWS Console
- [ ] Test application via ALB DNS
- [ ] Configure DNS (Route53 or external)
- [ ] Add SSL certificate (ACM)

---

## ☐ Testing

### Connectivity Tests
- [ ] SSH to bastion: `ssh -i ~/.ssh/prod-eks-key.pem ec2-user@<bastion-ip>`
- [ ] kubectl from bastion works
- [ ] Connect to RDS from bastion
- [ ] Application accessible via ALB
- [ ] Application can connect to database

### Functionality Tests
- [ ] Application health check passes
- [ ] Database queries work
- [ ] API endpoints respond correctly
- [ ] Frontend loads properly
- [ ] End-to-end user flow works

### Scaling Tests
- [ ] Manually scale deployment: `kubectl scale deployment app --replicas=5`
- [ ] Verify new pods start
- [ ] Configure HPA: `kubectl autoscale deployment app --cpu-percent=70 --min=2 --max=10`
- [ ] Generate load and verify autoscaling

---

## ☐ Monitoring & Alerting

### CloudWatch
- [ ] Review EKS control plane logs
- [ ] Review VPC Flow Logs
- [ ] Review RDS logs
- [ ] Set up log insights queries

### Metrics
- [ ] Monitor node CPU/memory
- [ ] Monitor pod CPU/memory
- [ ] Monitor RDS CPU/connections
- [ ] Monitor ALB request count

### Alerts (Optional)
- [ ] High CPU alert
- [ ] High memory alert
- [ ] Pod crash alert
- [ ] RDS connection alert
- [ ] Cost anomaly alert

---

## ☐ Documentation

### Update Documentation
- [ ] Document application architecture
- [ ] Document deployment process
- [ ] Document troubleshooting steps
- [ ] Document runbook for common issues
- [ ] Document disaster recovery plan

### Team Handoff
- [ ] Share AWS account access
- [ ] Share bastion SSH key securely
- [ ] Share kubectl config
- [ ] Share monitoring dashboards
- [ ] Conduct knowledge transfer session

---

## ☐ Backup & Disaster Recovery

### Backups
- [ ] Verify RDS automated backups enabled (30 days)
- [ ] Create manual RDS snapshot
- [ ] Export Terraform state: `terraform state pull > backup.tfstate`
- [ ] Backup Kubernetes manifests to Git
- [ ] Document backup locations

### Disaster Recovery Plan
- [ ] Document RDS restore procedure
- [ ] Document EKS cluster recreation steps
- [ ] Test restore from backup (in dev environment)
- [ ] Define RTO (Recovery Time Objective)
- [ ] Define RPO (Recovery Point Objective)

---

## ☐ Cost Optimization

### Review Costs
- [ ] Check AWS Cost Explorer
- [ ] Review resource utilization
- [ ] Identify unused resources
- [ ] Consider Reserved Instances for long-term
- [ ] Consider Savings Plans

### Optimization Actions
- [ ] Right-size EC2 instances if over/under-provisioned
- [ ] Consider Spot instances for non-critical workloads
- [ ] Review NAT Gateway usage (consider single NAT for dev)
- [ ] Set up auto-shutdown for non-production environments
- [ ] Enable S3 lifecycle policies for logs

---

## ☐ Production Readiness

### Final Checks
- [ ] All tests passing
- [ ] Monitoring working
- [ ] Alerts configured
- [ ] Documentation complete
- [ ] Team trained
- [ ] Backup tested
- [ ] Disaster recovery plan documented
- [ ] Security audit passed
- [ ] Performance benchmarks met
- [ ] Cost within budget

### Go-Live
- [ ] Schedule maintenance window
- [ ] Notify stakeholders
- [ ] Deploy to production
- [ ] Monitor closely for 24-48 hours
- [ ] Conduct post-deployment review

---

## 🎉 Deployment Complete!

### Next Steps
1. Monitor application health
2. Gather user feedback
3. Plan for continuous improvements
4. Schedule regular security audits
5. Review and optimize costs monthly

### Maintenance Schedule
- **Daily**: Check CloudWatch dashboards
- **Weekly**: Review logs for errors
- **Monthly**: Security patches, cost review
- **Quarterly**: Disaster recovery test, architecture review

---

## 📞 Emergency Contacts

- AWS Support: https://console.aws.amazon.com/support
- Team Lead: [Add contact]
- On-Call Engineer: [Add contact]
- Escalation Path: [Add details]

---

**Remember**: This is a production environment. Always test changes in dev/staging first!
