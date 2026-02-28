# Application Deployment Guide

Complete guide for deploying the 3-tier application to AWS EKS using the CI/CD pipeline.

---

## 📋 Prerequisites

Before deploying the application, ensure:

- ✅ AWS Infrastructure deployed (Phase 1 complete)
- ✅ Jenkins and SonarQube installed (Phase 2 complete)
- ✅ EKS cluster accessible via kubectl
- ✅ ECR repositories created
- ✅ AWS Load Balancer Controller installed

---

## 🏗️ Application Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AWS Cloud                          │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │         Application Load Balancer            │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │                                 │
│  ┌────────────────▼─────────────────────────────┐  │
│  │           EKS Cluster                        │  │
│  │                                              │  │
│  │  ┌──────────────┐      ┌──────────────┐    │  │
│  │  │   Frontend   │◄─────┤   Backend    │    │  │
│  │  │  (React.js)  │      │  (Node.js)   │    │  │
│  │  │  Port: 3000  │      │  Port: 5000  │    │  │
│  │  └──────────────┘      └──────┬───────┘    │  │
│  │                               │             │  │
│  │                        ┌──────▼───────┐    │  │
│  │                        │    MySQL     │    │  │
│  │                        │  Port: 3306  │    │  │
│  │                        └──────────────┘    │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Deployment Steps

### Step 1: Install AWS Load Balancer Controller

The AWS Load Balancer Controller is required for Ingress to work.

```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# Install eksctl if not already installed
curl --silent --location "https://github.com/weksctl/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=production-prod-base-project-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region=ap-south-1 \
  --approve

# Install Helm if not already installed
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-prod-base-project-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=<YOUR_VPC_ID>

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Get VPC ID:**
```bash
aws eks describe-cluster --name production-prod-base-project-eks --region ap-south-1 --query 'cluster.resourcesVpcConfig.vpcId' --output text
```

---

### Step 2: Create ECR Repositories

```bash
# Set variables
AWS_REGION="ap-south-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create frontend repository
aws ecr create-repository \
  --repository-name prod-base-project/frontend \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true

# Create backend repository
aws ecr create-repository \
  --repository-name prod-base-project/backend \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true

# Verify repositories
aws ecr describe-repositories --region $AWS_REGION
```

---

### Step 3: Update Jenkinsfile

Edit the `Jenkinsfile` in your repository and update:

```groovy
environment {
    AWS_REGION = 'ap-south-1'              // Your region
    AWS_ACCOUNT_ID = '616919332376'        // Your AWS account ID
    EKS_CLUSTER = 'production-prod-base-project-eks'  // Your cluster name
}
```

**Find your values:**
```bash
# AWS Account ID
aws sts get-caller-identity --query Account --output text

# EKS Cluster Name
aws eks list-clusters --region ap-south-1

# AWS Region
echo $AWS_DEFAULT_REGION
```

---

### Step 4: Update Kubernetes Manifests

Update image references in K8s manifests:

**File: `application/k8s-prod/frontend.yaml`**
```yaml
image: <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/prod-base-project/frontend:latest
```

**File: `application/k8s-prod/backend.yaml`**
```yaml
image: <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/prod-base-project/backend:latest
```

**Quick replace:**
```bash
cd application/k8s-prod
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# macOS
sed -i '' "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" frontend.yaml
sed -i '' "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" backend.yaml

# Linux
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" frontend.yaml
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" backend.yaml
```

---

### Step 5: Configure Secrets

**⚠️ IMPORTANT:** Never commit actual secrets to Git!

Generate strong secrets:
```bash
# Generate database password
DB_PASSWORD=$(openssl rand -base64 32)
echo "Database Password: $DB_PASSWORD"

# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 64)
echo "JWT Secret: $JWT_SECRET"

# Save these securely!
```

Update `application/k8s-prod/01-secrets.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
stringData:
  DB_HOST: "mysql"
  DB_USER: "root"
  DB_PASSWORD: "<YOUR_GENERATED_PASSWORD>"
  DB_NAME: "wanderlust"
  JWT_SECRET: "<YOUR_GENERATED_JWT_SECRET>"
```

**Better approach - Use AWS Secrets Manager:**
```bash
# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name prod-base-project/db-password \
  --secret-string "$DB_PASSWORD" \
  --region ap-south-1

aws secretsmanager create-secret \
  --name prod-base-project/jwt-secret \
  --secret-string "$JWT_SECRET" \
  --region ap-south-1
```

---

### Step 6: Create Jenkins Pipeline

1. **Open Jenkins:** `http://<jenkins-server-ip>:8080`

2. **Create New Pipeline:**
   - Click "New Item"
   - Name: `prod-base-project-cicd`
   - Type: Pipeline
   - Click OK

3. **Configure Pipeline:**
   - Description: "Production deployment pipeline for 3-tier application"
   - Pipeline section:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: `https://github.com/your-username/prod-base-project.git`
     - Credentials: (Add if private repo)
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
   - Save

4. **Configure Build Triggers (Optional):**
   - Poll SCM: `H/5 * * * *` (check every 5 minutes)
   - Or use GitHub webhooks for instant triggers

---

### Step 7: Run First Deployment

1. **Trigger Pipeline:**
   - Go to pipeline job
   - Click "Build Now"

2. **Monitor Execution:**
   - Click on build number (e.g., #1)
   - Click "Console Output"
   - Watch logs in real-time

3. **Expected Duration:** ~8-12 minutes

4. **Pipeline Stages:**
   ```
   ✓ Git Checkout
   ✓ Install Dependencies
   ✓ SonarQube Analysis
   ✓ Quality Gate
   ✓ Trivy FS Scan
   ✓ Build & Scan Docker Images
   ✓ Push to ECR
   ✓ Update K8s Manifests
   ✓ Deploy to EKS
   ✓ Verify Deployment
   ```

---

### Step 8: Verify Deployment

```bash
# Check namespace
kubectl get namespace production

# Check all resources
kubectl get all -n production

# Check pods
kubectl get pods -n production
# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxx-yyy             1/1     Running   0          2m
# backend-xxx-zzz             1/1     Running   0          2m
# frontend-aaa-bbb            1/1     Running   0          2m
# frontend-aaa-ccc            1/1     Running   0          2m
# mysql-0                     1/1     Running   0          3m

# Check services
kubectl get svc -n production

# Check ingress
kubectl get ingress -n production

# Get ALB URL
kubectl get ingress app-ingress -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

### Step 9: Access Application

```bash
# Get application URL
ALB_URL=$(kubectl get ingress app-ingress -n production -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$ALB_URL"

# Test frontend
curl http://$ALB_URL

# Test backend API
curl http://$ALB_URL/api/health

# Open in browser
open http://$ALB_URL  # macOS
xdg-open http://$ALB_URL  # Linux
```

**⏱️ Note:** ALB provisioning takes 2-3 minutes. If URL doesn't work immediately, wait and try again.

---

## 🔍 Troubleshooting

### Issue 1: Pods Not Starting

```bash
# Check pod status
kubectl get pods -n production

# Describe pod for details
kubectl describe pod <pod-name> -n production

# Check logs
kubectl logs <pod-name> -n production

# Common issues:
# - Image pull errors → Check ECR permissions
# - CrashLoopBackOff → Check application logs
# - Pending → Check node resources
```

### Issue 2: ALB Not Created

```bash
# Check ingress events
kubectl describe ingress app-ingress -n production

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Common issues:
# - Subnet tags missing
# - IAM permissions insufficient
# - Security group issues
```

**Fix subnet tags:**
```bash
# Public subnets need this tag:
# kubernetes.io/role/elb = 1

# Get subnet IDs
aws eks describe-cluster --name production-prod-base-project-eks --region ap-south-1 --query 'cluster.resourcesVpcConfig.subnetIds' --output text

# Tag subnets
aws ec2 create-tags --resources subnet-xxxxx --tags Key=kubernetes.io/role/elb,Value=1
```

### Issue 3: Backend Can't Connect to MySQL

```bash
# Check MySQL pod
kubectl get pod mysql-0 -n production
kubectl logs mysql-0 -n production

# Check backend logs
kubectl logs deployment/backend -n production

# Verify secrets
kubectl get secret app-secrets -n production -o yaml

# Test connection from backend pod
kubectl exec -it deployment/backend -n production -- sh
nc -zv mysql 3306
```

### Issue 4: Frontend Can't Reach Backend

```bash
# Check backend service
kubectl get svc backend -n production

# Check backend pods
kubectl get pods -l app=backend -n production

# Test from frontend pod
kubectl exec -it deployment/frontend -n production -- sh
curl http://backend:5000/api/health
```

### Issue 5: Image Pull Errors

```bash
# Error: "Failed to pull image"

# Check ECR permissions
aws ecr get-login-password --region ap-south-1

# Verify EKS node IAM role has ECR permissions
aws iam list-attached-role-policies --role-name <eks-node-role>

# Should include: AmazonEC2ContainerRegistryReadOnly

# Attach policy if missing
aws iam attach-role-policy \
  --role-name <eks-node-role> \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

---

## 🔄 Update Application

### Method 1: Via Jenkins Pipeline

1. Make code changes
2. Commit and push to Git
3. Trigger Jenkins pipeline
4. Pipeline automatically builds and deploys

### Method 2: Manual Update

```bash
# Build new image
cd application/3-Tier-DevSecOps-Mega-Project/client
docker build -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/prod-base-project/frontend:v2 .

# Push to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/prod-base-project/frontend:v2

# Update deployment
kubectl set image deployment/frontend frontend=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/prod-base-project/frontend:v2 -n production

# Watch rollout
kubectl rollout status deployment/frontend -n production
```

---

## ↩️ Rollback Deployment

```bash
# View rollout history
kubectl rollout history deployment/backend -n production

# Rollback to previous version
kubectl rollout undo deployment/backend -n production

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n production

# Verify rollback
kubectl rollout status deployment/backend -n production
```

---

## 📊 Monitoring Deployment

### View Logs

```bash
# Frontend logs
kubectl logs -f deployment/frontend -n production

# Backend logs
kubectl logs -f deployment/backend -n production

# MySQL logs
kubectl logs -f mysql-0 -n production

# All pods
kubectl logs -f -l app=backend -n production
```

### Check Resource Usage

```bash
# Pod resource usage
kubectl top pods -n production

# Node resource usage
kubectl top nodes

# Detailed pod info
kubectl describe pod <pod-name> -n production
```

### Check HPA Status

```bash
# View HPA
kubectl get hpa -n production

# Detailed HPA info
kubectl describe hpa frontend-hpa -n production
kubectl describe hpa backend-hpa -n production

# Watch HPA in real-time
kubectl get hpa -n production -w
```

---

## 🧪 Testing Application

### Health Checks

```bash
# Backend health
curl http://$ALB_URL/api/health

# Expected: {"status":"ok"}
```

### API Endpoints

```bash
# List all posts
curl http://$ALB_URL/api/posts

# Create post (requires authentication)
curl -X POST http://$ALB_URL/api/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Hello World"}'
```

### Load Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils -y

# Run load test
ab -n 1000 -c 10 http://$ALB_URL/

# Watch HPA scale
kubectl get hpa -n production -w
```

---

## 🔐 Security Best Practices

1. **Use Secrets Manager:**
   ```bash
   # Install External Secrets Operator
   helm repo add external-secrets https://charts.external-secrets.io
   helm install external-secrets external-secrets/external-secrets -n kube-system
   ```

2. **Enable Network Policies:**
   ```bash
   kubectl apply -f network-policies.yaml
   ```

3. **Use Pod Security Standards:**
   ```bash
   kubectl label namespace production pod-security.kubernetes.io/enforce=restricted
   ```

4. **Enable Image Scanning:**
   - ECR automatic scanning enabled
   - Trivy scans in pipeline

5. **Rotate Secrets Regularly:**
   ```bash
   # Update secret
   kubectl create secret generic app-secrets \
     --from-literal=DB_PASSWORD=new-password \
     --dry-run=client -o yaml | kubectl apply -f -
   
   # Restart pods to use new secret
   kubectl rollout restart deployment/backend -n production
   ```

---

## 🧹 Cleanup

### Delete Application Only

```bash
kubectl delete namespace production
```

### Delete Everything

```bash
# Delete application
kubectl delete namespace production

# Delete ALB controller
helm uninstall aws-load-balancer-controller -n kube-system

# Delete ECR repositories
aws ecr delete-repository --repository-name prod-base-project/frontend --force --region ap-south-1
aws ecr delete-repository --repository-name prod-base-project/backend --force --region ap-south-1

# Destroy infrastructure
cd terraform-resources/environments/production
terraform destroy
```

---

## 📚 Next Steps

1. **Setup Monitoring:** See [MONITORING.md](MONITORING.md)
2. **Configure Alerts:** Setup CloudWatch alarms
3. **Add Custom Domain:** Configure Route53 and ACM
4. **Enable HTTPS:** Add SSL certificate to ALB
5. **Setup Backups:** Configure MySQL backups
6. **Implement Blue-Green:** Advanced deployment strategies

---

**✅ Application Deployed Successfully!** Your 3-tier app is now running on production EKS cluster.
