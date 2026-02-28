# Production Deployment Guide

## ⚠️ CRITICAL: Security Fixes Applied

This guide reflects the production-ready fixes applied to the codebase.

### 🔒 Security Issues Fixed

1. ✅ **Removed hardcoded secrets** from K8s manifests
2. ✅ **Created Kubernetes Secrets** for sensitive data
3. ✅ **Changed to AWS ALB Ingress** (from nginx)
4. ✅ **Removed hardcoded domain names**
5. ✅ **Added security contexts** to pods
6. ✅ **Created .env.example files** (removed actual .env)
7. ✅ **Added HPA** for auto-scaling
8. ✅ **Updated to use ECR images** (not public Docker Hub)
9. ✅ **Added proper health probes**
10. ✅ **Increased storage** for production use

---

## 📋 Prerequisites

### 1. Infrastructure Deployed
```bash
cd terraform-resources/environments/production
terraform apply
```

### 2. Tools Installed
- AWS CLI configured
- kubectl installed
- Docker installed
- helm installed (for AWS Load Balancer Controller)


### 3. EKS Access Configured
```bash
aws eks update-kubeconfig --name production-eks-infra-eks --region us-east-1
kubectl get nodes  # Verify access
```

---

## 🚀 Deployment Steps

### Step 1: Create ECR Repositories

```bash
# Create repositories
aws ecr create-repository --repository-name frontend --region us-east-1
aws ecr create-repository --repository-name backend --region us-east-1

# Get login credentials
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### Step 2: Build and Push Docker Images

```bash
cd application/3-Tier-DevSecOps-Mega-Project

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Build and push frontend
cd client
docker build -t frontend:latest .
docker tag frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/frontend:latest

# Build and push backend
cd ../api
docker build -t backend:latest .
docker tag backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:latest
```

### Step 3: Update Kubernetes Manifests

Update image references in:
- `k8s-prod/frontend.yaml`
- `k8s-prod/backend.yaml`

Replace `<ACCOUNT_ID>` with your actual AWS account ID.

```bash
# Quick replace (macOS)
sed -i '' "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" k8s-prod/frontend.yaml
sed -i '' "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" k8s-prod/backend.yaml

# Quick replace (Linux)
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" k8s-prod/frontend.yaml
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" k8s-prod/backend.yaml
```

### Step 4: Generate Strong Secrets

```bash
# Generate strong password
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

echo "DB_PASSWORD: $DB_PASSWORD"
echo "JWT_SECRET: $JWT_SECRET"

# Save these securely!
```

### Step 5: Update Secrets Manifest

Edit `k8s-prod/01-secrets.yaml` and replace:
- `REPLACE_WITH_STRONG_PASSWORD` with your generated DB password
- `REPLACE_WITH_RANDOM_JWT_SECRET_KEY` with your generated JWT secret

**IMPORTANT:** Never commit this file with actual secrets!

### Step 6: Install AWS Load Balancer Controller

```bash
# Add IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create IAM role for service account
eksctl create iamserviceaccount \
  --cluster=production-eks-infra-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# Install controller
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

### Step 7: Deploy Application

```bash
cd application/k8s-prod

# Apply in order
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f sc.yaml
kubectl apply -f mysql.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n prod --timeout=300s

# Deploy backend and frontend
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml

# Deploy ingress
kubectl apply -f ingress.yaml

# Deploy HPA
kubectl apply -f hpa.yaml
```

### Step 8: Verify Deployment

```bash
# Check all resources
kubectl get all -n prod

# Check pods
kubectl get pods -n prod

# Check ingress
kubectl get ingress -n prod

# Get ALB DNS name
kubectl get ingress app-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Check logs
kubectl logs -f deployment/backend -n prod
kubectl logs -f deployment/frontend -n prod
```

### Step 9: Access Application

```bash
# Get ALB URL
ALB_URL=$(kubectl get ingress app-ingress -n prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Application URL: http://$ALB_URL"

# Test
curl http://$ALB_URL
curl http://$ALB_URL/api/health
```

---

## 🔍 Monitoring & Debugging

### Check Pod Status
```bash
kubectl get pods -n prod -w
kubectl describe pod <pod-name> -n prod
```

### View Logs
```bash
kubectl logs -f deployment/frontend -n prod
kubectl logs -f deployment/backend -n prod
kubectl logs -f statefulset/mysql -n prod
```

### Check HPA
```bash
kubectl get hpa -n prod
kubectl describe hpa frontend-hpa -n prod
kubectl describe hpa backend-hpa -n prod
```

### Check Ingress
```bash
kubectl describe ingress app-ingress -n prod
kubectl get events -n prod --sort-by='.lastTimestamp'
```

### Access MySQL
```bash
kubectl exec -it mysql-0 -n prod -- mysql -u root -p
# Enter password from secrets
```

---

## 🔐 Security Best Practices

### 1. Secrets Management

**Option A: Use AWS Secrets Manager (Recommended)**
```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n kube-system

# Create SecretStore (see documentation)
```

**Option B: Sealed Secrets**
```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

### 2. Network Policies

Create network policies to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 5000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: mysql
    ports:
    - protocol: TCP
      port: 3306
```

### 3. Pod Security Standards

```bash
kubectl label namespace prod pod-security.kubernetes.io/enforce=restricted
kubectl label namespace prod pod-security.kubernetes.io/audit=restricted
kubectl label namespace prod pod-security.kubernetes.io/warn=restricted
```

---

## 📊 Scaling

### Manual Scaling
```bash
kubectl scale deployment frontend --replicas=4 -n prod
kubectl scale deployment backend --replicas=6 -n prod
```

### Auto-scaling (HPA already configured)
```bash
# HPA will automatically scale based on CPU/Memory
kubectl get hpa -n prod -w
```

---

## 🔄 Updates & Rollbacks

### Update Application
```bash
# Build new image with tag
docker build -t backend:v2 .
docker tag backend:v2 $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:v2
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:v2

# Update deployment
kubectl set image deployment/backend backend=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/backend:v2 -n prod

# Watch rollout
kubectl rollout status deployment/backend -n prod
```

### Rollback
```bash
kubectl rollout undo deployment/backend -n prod
kubectl rollout history deployment/backend -n prod
```

---

## 🗑️ Cleanup

```bash
# Delete application
kubectl delete namespace prod

# Delete ALB controller
helm uninstall aws-load-balancer-controller -n kube-system

# Delete infrastructure
cd terraform-resources/environments/production
terraform destroy
```

---

## 📞 Troubleshooting

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
kubectl logs <backend-pod> -n prod
```

### HPA not scaling
```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n prod

# If metrics not available, install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## ✅ Production Checklist

- [ ] Infrastructure deployed via Terraform
- [ ] ECR repositories created
- [ ] Docker images built and pushed
- [ ] Secrets generated and updated
- [ ] AWS Load Balancer Controller installed
- [ ] Application deployed
- [ ] Ingress working (ALB created)
- [ ] HPA configured
- [ ] Monitoring set up
- [ ] Backups configured
- [ ] SSL certificate added (optional)
- [ ] Custom domain configured (optional)
- [ ] WAF enabled (optional)

---

**Status:** Production-ready with security best practices applied! 🚀


---

## 📊 Step 9: Install Monitoring Stack (Recommended)

### Quick Install

```bash
cd ../../monitoring
./install.sh
```

### Manual Install

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl apply -f namespace.yaml

# Install Prometheus + Grafana
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml \
  --wait

# Get Grafana credentials
echo "Username: admin"
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Access Monitoring Tools

**Grafana (Dashboards):**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit: http://localhost:3000
```

**Prometheus (Metrics):**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090
```

**AlertManager (Alerts):**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Visit: http://localhost:9093
```

### What Gets Monitored

✅ **Cluster Metrics:**
- Node CPU, memory, disk usage
- Pod resource consumption
- Network traffic
- Kubernetes API performance

✅ **Application Metrics:**
- HTTP request rates
- Response times
- Error rates
- Container metrics

✅ **Pre-configured Dashboards:**
- Kubernetes Cluster Overview
- Node Metrics
- Pod Metrics
- Namespace Resources
- Persistent Volumes

✅ **Alerts:**
- Node down
- High CPU/Memory usage
- Pod crash looping
- Disk space low
- API server errors

### Production Access (via ALB)

```bash
# Deploy Grafana ingress
kubectl apply -f grafana-ingress.yaml

# Get ALB URL
kubectl get ingress grafana-ingress -n monitoring
```

### Configure Alerts

Edit `alertmanager-config.yaml` for Slack/Email notifications:

```bash
kubectl apply -f alertmanager-config.yaml
kubectl rollout restart statefulset/alertmanager-kube-prometheus-stack-alertmanager -n monitoring
```

### Complete Monitoring Guide

See `monitoring/MONITORING-GUIDE.md` for:
- Custom dashboards
- Application metrics
- Alert configuration
- Troubleshooting
- Cost optimization

---
