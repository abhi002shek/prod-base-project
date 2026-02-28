# Quick Start Guide

## 🚀 Deploy in 30 Minutes

### Prerequisites
- AWS CLI configured
- kubectl installed
- Docker installed
- Terraform installed

---

## Step 1: Deploy Infrastructure

```bash
cd terraform-resources/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

cd ../environments/production
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: Update key_name, IPs, password
terraform init && terraform apply
```

---

## Step 2: Configure kubectl

```bash
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1
kubectl get nodes
```

---

## Step 3: Build & Push Images

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Create ECR repos
aws ecr create-repository --repository-name frontend
aws ecr create-repository --repository-name backend

# Login
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build & push
cd application/3-Tier-DevSecOps-Mega-Project/client
docker build -t frontend:latest .
docker tag frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend:latest

cd ../api
docker build -t backend:latest .
docker tag backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:latest
```

---

## Step 4: Update Manifests

```bash
cd ../../k8s-prod

# Update image references
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" frontend.yaml backend.yaml

# Generate secrets
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Update 01-secrets.yaml with generated values
# Replace REPLACE_WITH_STRONG_PASSWORD with $DB_PASSWORD
# Replace REPLACE_WITH_RANDOM_JWT_SECRET_KEY with $JWT_SECRET
```

---

## Step 5: Install ALB Controller

```bash
# Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=production-eks-infra-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=production-eks-infra-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

---

## Step 6: Deploy Application

```bash
cd application/k8s-prod

kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f sc.yaml
kubectl apply -f mysql.yaml

# Wait for MySQL
kubectl wait --for=condition=ready pod -l app=mysql -n prod --timeout=300s

kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

---

## Step 7: Access Application

```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress app-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$ALB_URL"

# Test
curl http://$ALB_URL
```

---

## 🔍 Verify Deployment

```bash
# Check all resources
kubectl get all -n prod

# Check pods
kubectl get pods -n prod

# Check HPA
kubectl get hpa -n prod

# View logs
kubectl logs -f deployment/frontend -n prod
kubectl logs -f deployment/backend -n prod
```

---

## 🐛 Quick Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n prod
kubectl logs <pod-name> -n prod
```

### ALB not created
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress app-ingress -n prod
```

### Database connection issues
```bash
kubectl exec -it <backend-pod> -n prod -- env | grep DB_
```

---

## 🗑️ Cleanup

```bash
kubectl delete namespace prod
helm uninstall aws-load-balancer-controller -n kube-system
cd terraform-resources/environments/production
terraform destroy
```

---

## 📚 Full Documentation

- **Complete Guide:** `application/DEPLOYMENT-GUIDE.md`
- **Security Fixes:** `SECURITY-FIXES.md`
- **Review Summary:** `PRODUCTION-REVIEW-SUMMARY.md`

---

**Total Time:** ~30 minutes  
**Difficulty:** Intermediate  
**Cost:** ~$414/month
