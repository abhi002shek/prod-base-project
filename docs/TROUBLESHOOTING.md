# Troubleshooting Guide

Common issues and solutions for the production infrastructure and application deployment.

---

## 🎯 Quick Diagnosis

```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check specific namespace
kubectl get all -n production

# View recent events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/backend -n production
```

---

## 🏗️ Infrastructure Issues

### Issue 1: Terraform Apply Fails

**Error:** `Error creating VPC: VpcLimitExceeded`

**Solution:**
```bash
# Check VPC limit
aws ec2 describe-account-attributes --attribute-names max-vpcs

# Delete unused VPCs
aws ec2 describe-vpcs --query 'Vpcs[?Tags==`null`].VpcId' --output text
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# Or request limit increase
aws service-quotas request-service-quota-increase \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --desired-value 10
```

---

### Issue 2: EKS Cluster Creation Fails

**Error:** `Error creating EKS Cluster: ResourceInUseException`

**Solution:**
```bash
# Check existing clusters
aws eks list-clusters --region ap-south-1

# Delete old cluster if needed
aws eks delete-cluster --name old-cluster --region ap-south-1

# Wait for deletion
aws eks describe-cluster --name old-cluster --region ap-south-1
```

---

### Issue 3: RDS Creation Fails

**Error:** `DBSubnetGroupDoesNotCoverEnoughAZs`

**Solution:**
- Ensure subnets span at least 2 availability zones
- Check terraform VPC module configuration
- Verify subnet CIDR blocks don't overlap

```bash
# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

---

### Issue 4: Bastion Host Can't Connect

**Error:** `Connection timed out`

**Solution:**
```bash
# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify your IP is allowed
curl ifconfig.me

# Update security group
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32
```

---

## 🔧 Jenkins Issues

### Issue 1: Jenkins Won't Start

**Error:** `Failed to start Jenkins`

**Solution:**
```bash
# Check Java version
java -version  # Should be 17

# Check Jenkins status
sudo systemctl status jenkins

# View logs
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins
```

---

### Issue 2: Docker Permission Denied

**Error:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

---

### Issue 3: kubectl Command Not Found

**Error:** `kubectl: command not found`

**Solution:**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Create symlink
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl

# Verify
kubectl version --client
```

---

### Issue 4: Pipeline Fails at SonarQube Stage

**Error:** `Unable to connect to SonarQube server`

**Solution:**
```bash
# Check SonarQube is running
sudo docker ps | grep sonarqube

# Check SonarQube logs
sudo docker logs sonarqube

# Restart SonarQube
sudo docker restart sonarqube

# Verify connectivity from Jenkins
curl http://<sonarqube-ip>:9000
```

---

### Issue 5: AWS Credentials Not Working

**Error:** `Unable to locate credentials`

**Solution:**

**Option A: Using IAM Role (Recommended)**
```bash
# Verify IAM role is attached
aws ec2 describe-instances --instance-ids i-xxxxx \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Attach role if missing
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=JenkinsEC2Role
```

**Option B: Using Credentials**
```bash
# Configure AWS CLI
aws configure

# Test
aws sts get-caller-identity
```

---

## 🐳 Docker Issues

### Issue 1: Image Build Fails

**Error:** `failed to solve with frontend dockerfile.v0`

**Solution:**
```bash
# Check Dockerfile syntax
docker build --no-cache -t test .

# Check disk space
df -h

# Clean up Docker
docker system prune -a
```

---

### Issue 2: Push to ECR Fails

**Error:** `denied: Your authorization token has expired`

**Solution:**
```bash
# Re-authenticate
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Verify
docker push $ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/test:latest
```

---

### Issue 3: Image Pull Error in EKS

**Error:** `Failed to pull image: access denied`

**Solution:**
```bash
# Check EKS node IAM role
aws iam list-attached-role-policies --role-name eks-node-role

# Attach ECR policy
aws iam attach-role-policy \
  --role-name eks-node-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Verify from node
kubectl run test --image=$ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/test:latest
```

---

## ☸️ Kubernetes Issues

### Issue 1: Pods Stuck in Pending

**Error:** `0/3 nodes are available: insufficient cpu`

**Solution:**
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Scale node group
aws eks update-nodegroup-config \
  --cluster-name production-prod-base-project-eks \
  --nodegroup-name production-node-group \
  --scaling-config minSize=2,maxSize=6,desiredSize=4

# Or reduce pod resource requests
kubectl edit deployment backend -n production
```

---

### Issue 2: Pods CrashLoopBackOff

**Error:** `Back-off restarting failed container`

**Solution:**
```bash
# Check pod logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous

# Describe pod for events
kubectl describe pod <pod-name> -n production

# Common causes:
# - Application error → Check logs
# - Missing environment variables → Check secrets
# - Health check failing → Adjust probes
# - OOMKilled → Increase memory limits
```

---

### Issue 3: Service Not Accessible

**Error:** `Connection refused`

**Solution:**
```bash
# Check service
kubectl get svc backend -n production
kubectl describe svc backend -n production

# Check endpoints
kubectl get endpoints backend -n production

# Test from another pod
kubectl run test --image=busybox -it --rm -- sh
wget -O- http://backend:5000/api/health

# Check pod labels match service selector
kubectl get pods -n production --show-labels
```

---

### Issue 4: Ingress Not Creating ALB

**Error:** `ALB not provisioned`

**Solution:**
```bash
# Check ALB controller
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check ingress
kubectl describe ingress app-ingress -n production

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'Subnets[*].[SubnetId,Tags[?Key==`kubernetes.io/role/elb`].Value]'

# Add tags if missing
aws ec2 create-tags \
  --resources subnet-xxxxx \
  --tags Key=kubernetes.io/role/elb,Value=1
```

---

### Issue 5: PVC Stuck in Pending

**Error:** `waiting for a volume to be created`

**Solution:**
```bash
# Check storage class
kubectl get storageclass

# Check PVC
kubectl describe pvc mysql-pvc -n production

# Verify EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi

# Check node IAM role has EBS permissions
aws iam list-attached-role-policies --role-name eks-node-role
```

---

## 🗄️ Database Issues

### Issue 1: MySQL Pod Won't Start

**Error:** `mysqld: Can't create/write to file`

**Solution:**
```bash
# Check PVC
kubectl get pvc -n production
kubectl describe pvc mysql-pvc -n production

# Check pod events
kubectl describe pod mysql-0 -n production

# Check logs
kubectl logs mysql-0 -n production

# Verify permissions
kubectl exec -it mysql-0 -n production -- ls -la /var/lib/mysql
```

---

### Issue 2: Backend Can't Connect to MySQL

**Error:** `ECONNREFUSED 127.0.0.1:3306`

**Solution:**
```bash
# Check MySQL service
kubectl get svc mysql -n production

# Test connection from backend pod
kubectl exec -it deployment/backend -n production -- sh
nc -zv mysql 3306

# Check environment variables
kubectl exec deployment/backend -n production -- env | grep DB_

# Verify secrets
kubectl get secret app-secrets -n production -o yaml
```

---

### Issue 3: Database Connection Pool Exhausted

**Error:** `Too many connections`

**Solution:**
```bash
# Check MySQL connections
kubectl exec -it mysql-0 -n production -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Increase max connections
kubectl exec -it mysql-0 -n production -- mysql -u root -p -e "SET GLOBAL max_connections = 500;"

# Or update MySQL config
kubectl edit statefulset mysql -n production
# Add: --max-connections=500
```

---

## 🌐 Network Issues

### Issue 1: DNS Resolution Fails

**Error:** `getaddrinfo ENOTFOUND backend`

**Solution:**
```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS from pod
kubectl run test --image=busybox -it --rm -- nslookup backend.production.svc.cluster.local

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

---

### Issue 2: External Traffic Not Reaching Pods

**Error:** `504 Gateway Timeout`

**Solution:**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify ALB target groups
aws elbv2 describe-target-groups

# Check target health
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# Verify pod health probes
kubectl describe pod <pod-name> -n production
```

---

### Issue 3: Inter-Pod Communication Blocked

**Error:** `Connection timed out`

**Solution:**
```bash
# Check network policies
kubectl get networkpolicies -n production

# Temporarily delete to test
kubectl delete networkpolicy <policy-name> -n production

# Check security groups
aws eks describe-cluster --name production-prod-base-project-eks \
  --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId'
```

---

## 🔐 Security Issues

### Issue 1: Secrets Not Found

**Error:** `Error from server (NotFound): secrets "app-secrets" not found`

**Solution:**
```bash
# Check if secret exists
kubectl get secrets -n production

# Create secret
kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=your-password \
  --from-literal=JWT_SECRET=your-secret \
  -n production

# Verify
kubectl describe secret app-secrets -n production
```

---

### Issue 2: RBAC Permission Denied

**Error:** `User "system:serviceaccount:default:default" cannot get pods`

**Solution:**
```bash
# Create service account
kubectl create serviceaccount app-sa -n production

# Create role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n production

# Create role binding
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=production:app-sa \
  -n production

# Update deployment to use service account
kubectl patch deployment backend -n production \
  -p '{"spec":{"template":{"spec":{"serviceAccountName":"app-sa"}}}}'
```

---

## 📊 Monitoring Issues

### Issue 1: Prometheus Not Scraping Targets

**Error:** `Context deadline exceeded`

**Solution:**
```bash
# Check ServiceMonitor
kubectl get servicemonitor -n production
kubectl describe servicemonitor backend-monitor -n production

# Verify service has correct labels
kubectl get svc backend -n production --show-labels

# Check Prometheus config
kubectl get secret prometheus-kube-prometheus-stack-prometheus \
  -n monitoring -o yaml | grep -A 10 serviceMonitorSelector
```

---

### Issue 2: Grafana Shows No Data

**Error:** `No data`

**Solution:**
```bash
# Check Prometheus data source
# Grafana → Configuration → Data Sources → Prometheus → Test

# Verify Prometheus is collecting metrics
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check time range in Grafana dashboard
```

---

## 🚀 Performance Issues

### Issue 1: High CPU Usage

**Solution:**
```bash
# Identify high CPU pods
kubectl top pods -n production --sort-by=cpu

# Check HPA
kubectl get hpa -n production

# Scale manually if needed
kubectl scale deployment backend --replicas=6 -n production

# Investigate application
kubectl logs -f deployment/backend -n production
```

---

### Issue 2: High Memory Usage

**Solution:**
```bash
# Identify high memory pods
kubectl top pods -n production --sort-by=memory

# Check for memory leaks
kubectl logs deployment/backend -n production | grep -i "memory\|heap"

# Increase memory limits
kubectl set resources deployment backend \
  --limits=memory=2Gi \
  --requests=memory=1Gi \
  -n production
```

---

### Issue 3: Slow Response Times

**Solution:**
```bash
# Check pod resource usage
kubectl top pods -n production

# Check database performance
kubectl exec -it mysql-0 -n production -- mysql -u root -p -e "SHOW PROCESSLIST;"

# Enable query logging
kubectl exec -it mysql-0 -n production -- mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON';"

# Check network latency
kubectl exec -it deployment/backend -n production -- ping mysql
```

---

## 🧹 Cleanup Issues

### Issue 1: Namespace Stuck in Terminating

**Error:** `namespace "production" is stuck in Terminating state`

**Solution:**
```bash
# Check what's blocking
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n production

# Force delete finalizers
kubectl get namespace production -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/production/finalize" -f -
```

---

### Issue 2: PVC Won't Delete

**Error:** `persistentvolumeclaim "mysql-pvc" is stuck in Terminating`

**Solution:**
```bash
# Check what's using it
kubectl describe pvc mysql-pvc -n production

# Delete pods using it
kubectl delete pod mysql-0 -n production --force --grace-period=0

# Remove finalizers
kubectl patch pvc mysql-pvc -n production -p '{"metadata":{"finalizers":null}}'
```

---

## 📞 Getting Help

### Collect Diagnostic Information

```bash
# Create diagnostic bundle
kubectl cluster-info dump --output-directory=./cluster-dump

# Get all resources
kubectl get all --all-namespaces -o yaml > all-resources.yaml

# Get events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > events.log

# Get logs
kubectl logs -n production deployment/backend > backend.log
kubectl logs -n production deployment/frontend > frontend.log
```

### Useful Commands

```bash
# Check cluster version
kubectl version

# Check node status
kubectl get nodes -o wide

# Check all pods
kubectl get pods --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check API server
kubectl get --raw /healthz

# Check component status
kubectl get componentstatuses
```

---

## 📚 Additional Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Jenkins Troubleshooting](https://www.jenkins.io/doc/book/troubleshooting/)
- [Docker Troubleshooting](https://docs.docker.com/config/daemon/troubleshoot/)

---

**💡 Tip:** Always check logs first! Most issues can be diagnosed from pod logs and events.
