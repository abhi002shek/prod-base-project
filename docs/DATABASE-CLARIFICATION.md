# Database Clarification - MySQL vs RDS PostgreSQL

## ⚠️ Important Note About Databases

This project uses **TWO different databases**, but only ONE is actually used by the application.

---

## 🗄️ Database Setup Explained

### 1. MySQL (ACTUALLY USED BY APPLICATION) ✅

**Location:** Running inside Kubernetes cluster as a StatefulSet
**File:** `application/k8s-prod/mysql.yaml`
**Purpose:** Primary database for the 3-tier application
**Connection:** Backend → MySQL Pod (port 3306)

**Why MySQL in Kubernetes?**
- Easier for development and testing
- No additional AWS costs
- Simpler deployment
- Good for demo/portfolio projects
- Application code is already configured for MySQL

**Configuration:**
```yaml
# In k8s-prod/mysql.yaml
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1
```

**Connection from Backend:**
```javascript
// Backend connects to:
DB_HOST: mysql
DB_PORT: 3306
DB_NAME: wanderlust
```

---

### 2. RDS PostgreSQL (NOT USED BY APPLICATION) ❌

**Location:** AWS RDS service (managed database)
**File:** `terraform-resources/modules/rds/`
**Purpose:** Provisioned by Terraform but NOT connected to application
**Status:** Created but idle

**Why is RDS provisioned?**
- Demonstrates production-grade infrastructure
- Shows Terraform capability
- Production best practice (managed database)
- Multi-AZ for high availability
- Automated backups

**Why NOT used by application?**
- Application code is configured for MySQL, not PostgreSQL
- Would require code changes to switch
- Additional cost (~$30/month)
- Overkill for demo project

---

## 🎯 What You Should Know

### Current Setup:
```
Frontend (React) 
    ↓
Backend (Node.js) 
    ↓
MySQL (Kubernetes Pod) ✅ USED
    
RDS PostgreSQL (AWS) ❌ NOT USED (just provisioned)
```

### Traffic Flow:
```
User → ALB → Frontend Pod → Backend Pod → MySQL Pod
                                            ↓
                                    (Persistent Volume)
```

---

## 💰 Cost Impact

| Database | Monthly Cost | Status |
|----------|--------------|--------|
| MySQL in K8s | $0 (uses node resources) | ✅ Used |
| RDS PostgreSQL | ~$30 | ❌ Not used |

**Recommendation:** Remove RDS from Terraform to save $30/month

---

## 🔧 Options Going Forward

### Option 1: Keep MySQL Only (Recommended for Demo)

**Pros:**
- No code changes needed
- Lower cost
- Simpler architecture
- Good for portfolio/learning

**Cons:**
- Not production best practice
- Manual backup management
- Single point of failure

**Action:** Remove RDS module from Terraform

```bash
# Comment out in terraform-resources/environments/production/main.tf
# module "rds" {
#   source = "../../modules/rds"
#   ...
# }
```

---

### Option 2: Switch to RDS PostgreSQL (Production Approach)

**Pros:**
- Production best practice
- Managed backups
- Multi-AZ high availability
- Automated maintenance
- Better performance

**Cons:**
- Requires code changes
- Additional cost ($30/month)
- More complex setup

**Action:** Update application to use RDS

1. Change backend database driver (mysql → pg)
2. Update connection string to RDS endpoint
3. Remove MySQL StatefulSet from k8s-prod/
4. Update secrets with RDS credentials

---

### Option 3: Keep Both (Learning/Demo)

**Pros:**
- Shows both approaches
- Demonstrates flexibility
- Good for learning

**Cons:**
- Higher cost
- Confusing for viewers
- RDS sits idle

**Action:** Add note in documentation explaining both

---

## 📝 Documentation Updates

All documentation has been updated to clarify:

✅ MySQL is the primary database (used by app)
✅ RDS PostgreSQL is optional (not used by app)
✅ Cost tables show RDS as optional
✅ Architecture diagrams note MySQL in Kubernetes
✅ LinkedIn posts mention MySQL as primary database

---

## 🎓 For Interviews / Presentations

**When asked about database:**

"The application uses MySQL running as a StatefulSet in Kubernetes. This provides a simple, cost-effective solution for the demo. In production, I would migrate to AWS RDS for managed backups, Multi-AZ deployment, and automated maintenance. The Terraform code includes an RDS module to demonstrate production-grade infrastructure provisioning, though it's not currently connected to the application."

**Key points to mention:**
- Understand trade-offs between managed vs self-hosted
- Know when to use each approach
- Can implement either based on requirements
- Cost vs reliability considerations

---

## 🔍 How to Verify

### Check what's actually running:
```bash
# MySQL in Kubernetes (USED)
kubectl get statefulset mysql -n production
kubectl get pods -l app=mysql -n production

# RDS in AWS (NOT USED)
aws rds describe-db-instances --region ap-south-1
```

### Check backend connection:
```bash
# View backend environment variables
kubectl exec -it deployment/backend -n production -- env | grep DB_

# Should show:
# DB_HOST=mysql (not RDS endpoint)
# DB_PORT=3306
# DB_NAME=wanderlust
```

---

## ✅ Summary

**Current State:**
- ✅ MySQL in Kubernetes = USED by application
- ❌ RDS PostgreSQL = NOT USED (just provisioned)

**Recommendation:**
- Keep MySQL for demo/portfolio
- Remove RDS to save cost
- Mention both approaches in interviews

**Documentation:**
- All docs updated to clarify this
- No more confusion between MySQL and PostgreSQL

---

**🎯 Bottom Line:** Your app uses MySQL in Kubernetes. RDS is just infrastructure provisioning practice.
