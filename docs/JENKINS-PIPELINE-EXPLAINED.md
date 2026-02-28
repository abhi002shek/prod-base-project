# Jenkins Pipeline Explained - Step by Step

Complete breakdown of the CI/CD pipeline with detailed explanations of each stage.

---

## 🎯 Pipeline Overview

The Jenkins pipeline automates the entire deployment process from code commit to production deployment on EKS. It includes:

- Code quality analysis
- Security scanning
- Docker image building
- Container vulnerability scanning
- Deployment to Kubernetes

**Total Pipeline Duration:** ~8-12 minutes

---

## 📋 Pipeline Structure

```groovy
pipeline {
    agent any
    tools { ... }
    environment { ... }
    stages { ... }
    post { ... }
}
```

Let's break down each section:

---

## 🔧 Section 1: Agent & Tools

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'nodejs23'
    }
```

**What it does:**
- `agent any` - Pipeline can run on any available Jenkins agent/node
- `tools` - Automatically installs and configures NodeJS 23 for this pipeline

**Why we need it:**
- Frontend and backend are Node.js applications
- Need npm to install dependencies and build

---

## 🌍 Section 2: Environment Variables

```groovy
environment {
    SCANNER_HOME = tool 'sonar-scanner'
    AWS_REGION = 'ap-south-1'
    AWS_ACCOUNT_ID = '616919332376'
    ECR_FRONTEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-base-project/frontend"
    ECR_BACKEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-base-project/backend"
    EKS_CLUSTER = 'production-prod-base-project-eks'
}
```

**What it does:**
- Defines variables used throughout the pipeline
- Makes pipeline configuration centralized and easy to modify

**Variables explained:**
- `SCANNER_HOME` - Path to SonarQube scanner tool
- `AWS_REGION` - AWS region where resources are deployed
- `AWS_ACCOUNT_ID` - Your AWS account ID (⚠️ Update this!)
- `ECR_FRONTEND` - Full ECR repository URL for frontend images
- `ECR_BACKEND` - Full ECR repository URL for backend images
- `EKS_CLUSTER` - Name of your EKS cluster

**⚠️ IMPORTANT:** Update `AWS_ACCOUNT_ID` and `AWS_REGION` to match your setup!

---

## 📦 Stage 1: Git Checkout

```groovy
stage('Git Checkout') {
    steps {
        git branch: 'main', url: 'https://github.com/abhi002shek/prod-base-project.git'
    }
}
```

**What it does:**
- Clones the Git repository
- Checks out the `main` branch
- Downloads all application code to Jenkins workspace

**Why we need it:**
- Get the latest code for building and deployment
- Ensures we're deploying the most recent version

**Duration:** ~10-20 seconds

---

## 📥 Stage 2: Install Dependencies

```groovy
stage('Install Dependencies') {
    parallel {
        stage('Frontend Dependencies') {
            steps {
                dir('application/3-Tier-DevSecOps-Mega-Project/client') {
                    sh 'npm install'
                }
            }
        }
        stage('Backend Dependencies') {
            steps {
                dir('application/3-Tier-DevSecOps-Mega-Project/api') {
                    sh 'npm install'
                }
            }
        }
    }
}
```

**What it does:**
- Installs npm packages for both frontend and backend
- Runs in parallel to save time
- Creates `node_modules` directories

**Why we need it:**
- Required for SonarQube analysis
- Validates package.json dependencies
- Ensures all libraries are available

**Duration:** ~1-2 minutes (parallel execution)

**Key concept - Parallel execution:**
- Both frontend and backend install simultaneously
- Reduces total pipeline time by ~50%

---

## 🔍 Stage 3: SonarQube Analysis

```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('sonar') {
            sh '''
                $SCANNER_HOME/bin/sonar-scanner \
                -Dsonar.projectKey=prod-base-project \
                -Dsonar.projectName=prod-base-project \
                -Dsonar.sources=application/3-Tier-DevSecOps-Mega-Project \
                -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.log
            '''
        }
    }
}
```

**What it does:**
- Scans code for quality issues, bugs, and code smells
- Sends analysis results to SonarQube server
- Checks code against quality standards

**Parameters explained:**
- `withSonarQubeEnv('sonar')` - Uses SonarQube server configured in Jenkins
- `-Dsonar.projectKey` - Unique identifier for project
- `-Dsonar.projectName` - Display name in SonarQube
- `-Dsonar.sources` - Directory to scan
- `-Dsonar.exclusions` - Files/folders to skip (dependencies, logs)

**What it checks:**
- Code complexity
- Duplicate code
- Security vulnerabilities
- Code coverage
- Maintainability issues
- Reliability issues

**Duration:** ~1-2 minutes

---

## ✅ Stage 4: Quality Gate

```groovy
stage('Quality Gate') {
    steps {
        script {
            timeout(time: 5, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
            }
        }
    }
}
```

**What it does:**
- Waits for SonarQube to finish analysis
- Checks if code meets quality standards
- Decides whether to continue or fail pipeline

**Parameters explained:**
- `timeout(time: 5, unit: 'MINUTES')` - Max wait time for results
- `waitForQualityGate` - Waits for SonarQube quality gate result
- `abortPipeline: false` - Continue even if quality gate fails (warning only)
- `credentialsId: 'sonar-token'` - Token to authenticate with SonarQube

**Quality Gate checks:**
- Code coverage > threshold
- No critical bugs
- No security hotspots
- Maintainability rating

**Duration:** ~30 seconds

**💡 Tip:** Set `abortPipeline: true` in production to enforce quality standards

---

## 🛡️ Stage 5: Trivy Filesystem Scan

```groovy
stage('Trivy FS Scan') {
    steps {
        sh 'trivy fs --format table -o trivy-fs-report.html application/3-Tier-DevSecOps-Mega-Project'
    }
}
```

**What it does:**
- Scans source code and dependencies for vulnerabilities
- Checks for known security issues in npm packages
- Generates HTML report

**Parameters explained:**
- `trivy fs` - Filesystem scan mode
- `--format table` - Output format
- `-o trivy-fs-report.html` - Save report to file
- Last parameter - Directory to scan

**What it detects:**
- Vulnerable npm packages
- Outdated dependencies with known CVEs
- Security issues in application code
- License compliance issues

**Duration:** ~30-60 seconds

---

## 🐳 Stage 6: Build & Scan Docker Images

```groovy
stage('Build & Scan Docker Images') {
    parallel {
        stage('Frontend') {
            stages {
                stage('Build Frontend') {
                    steps {
                        dir('application/3-Tier-DevSecOps-Mega-Project/client') {
                            sh "docker build -t ${ECR_FRONTEND}:${BUILD_NUMBER} ."
                            sh "docker tag ${ECR_FRONTEND}:${BUILD_NUMBER} ${ECR_FRONTEND}:latest"
                        }
                    }
                }
                stage('Scan Frontend') {
                    steps {
                        sh "trivy image --format table -o trivy-frontend-report.html ${ECR_FRONTEND}:${BUILD_NUMBER}"
                    }
                }
            }
        }
        stage('Backend') {
            stages {
                stage('Build Backend') {
                    steps {
                        dir('application/3-Tier-DevSecOps-Mega-Project/api') {
                            sh "docker build -t ${ECR_BACKEND}:${BUILD_NUMBER} ."
                            sh "docker tag ${ECR_BACKEND}:${BUILD_NUMBER} ${ECR_BACKEND}:latest"
                        }
                    }
                }
                stage('Scan Backend') {
                    steps {
                        sh "trivy image --format table -o trivy-backend-report.html ${ECR_BACKEND}:${BUILD_NUMBER}"
                    }
                }
            }
        }
    }
}
```

**What it does:**
- Builds Docker images for frontend and backend
- Tags images with build number and 'latest'
- Scans images for vulnerabilities
- Runs in parallel for both services

**Build process:**
1. Navigate to application directory
2. Run `docker build` using Dockerfile
3. Tag image with build number (e.g., `:123`)
4. Tag same image as `:latest`

**Scan process:**
- Scans the built Docker image
- Checks base image vulnerabilities
- Checks installed packages
- Generates HTML report

**Why two tags?**
- `BUILD_NUMBER` - Specific version for rollback capability
- `latest` - Always points to most recent build

**Duration:** ~3-5 minutes (parallel execution)

---

## 📤 Stage 7: Push to ECR

```groovy
stage('Push to ECR') {
    steps {
        script {
            withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    docker push ${ECR_FRONTEND}:${BUILD_NUMBER}
                    docker push ${ECR_FRONTEND}:latest
                    docker push ${ECR_BACKEND}:${BUILD_NUMBER}
                    docker push ${ECR_BACKEND}:latest
                '''
            }
        }
    }
}
```

**What it does:**
- Authenticates with AWS ECR
- Pushes Docker images to ECR repositories
- Uploads both versioned and latest tags

**Step by step:**
1. `withCredentials` - Loads AWS credentials from Jenkins
2. `aws ecr get-login-password` - Gets ECR authentication token
3. `docker login` - Authenticates Docker with ECR
4. `docker push` - Uploads images to ECR (4 images total)

**Why push to ECR?**
- Private container registry
- Integrated with AWS IAM
- Fast image pulls from EKS
- Automatic image scanning
- Lifecycle policies for cleanup

**Duration:** ~2-3 minutes (depends on image size and network)

---

## 📝 Stage 8: Update K8s Manifests

```groovy
stage('Update K8s Manifests') {
    steps {
        dir('application/k8s-prod') {
            sh """
                sed -i 's|image:.*frontend.*|image: ${ECR_FRONTEND}:${BUILD_NUMBER}|g' frontend.yaml
                sed -i 's|image:.*backend.*|image: ${ECR_BACKEND}:${BUILD_NUMBER}|g' backend.yaml
            """
        }
    }
}
```

**What it does:**
- Updates Kubernetes YAML files with new image tags
- Replaces old image references with newly built images
- Ensures deployment uses correct version

**How it works:**
- `sed -i` - Edit file in-place
- `'s|old|new|g'` - Search and replace pattern
- Finds lines with `image:` and updates tag to current build number

**Example:**
```yaml
# Before
image: 616919332376.dkr.ecr.ap-south-1.amazonaws.com/prod-base-project/frontend:122

# After
image: 616919332376.dkr.ecr.ap-south-1.amazonaws.com/prod-base-project/frontend:123
```

**Duration:** <5 seconds

---

## 🚀 Stage 9: Deploy to EKS

```groovy
stage('Deploy to EKS') {
    steps {
        script {
            withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                sh '''
                    aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}
                    kubectl apply -f application/k8s-prod/00-namespace.yaml
                    kubectl apply -f application/k8s-prod/01-secrets.yaml
                    kubectl apply -f application/k8s-prod/mysql.yaml
                    sleep 30
                    kubectl apply -f application/k8s-prod/backend.yaml
                    kubectl apply -f application/k8s-prod/frontend.yaml
                    kubectl apply -f application/k8s-prod/ingress.yaml
                    kubectl apply -f application/k8s-prod/hpa.yaml
                '''
            }
        }
    }
}
```

**What it does:**
- Configures kubectl to connect to EKS cluster
- Applies Kubernetes manifests in correct order
- Deploys application to production namespace

**Deployment order explained:**

1. **Namespace** - Creates isolated environment
2. **Secrets** - Database passwords, JWT secrets
3. **MySQL** - Database (StatefulSet)
4. **Sleep 30** - Wait for MySQL to be ready
5. **Backend** - API server (connects to MySQL)
6. **Frontend** - React app (connects to backend)
7. **Ingress** - AWS ALB for external access
8. **HPA** - Auto-scaling configuration

**Why this order?**
- Dependencies must exist before dependents
- Database must be ready before backend starts
- Backend must be ready before frontend connects

**What happens during deployment:**
- Kubernetes pulls new images from ECR
- Creates/updates pods with new containers
- Performs rolling update (zero downtime)
- Old pods terminate after new pods are ready

**Duration:** ~1-2 minutes

---

## ✅ Stage 10: Verify Deployment

```groovy
stage('Verify Deployment') {
    steps {
        withCredentials([aws(credentialsId: 'aws-creds', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            sh '''
                kubectl get pods -n production
                kubectl get svc -n production
                kubectl get ingress -n production
            '''
        }
    }
}
```

**What it does:**
- Checks deployment status
- Lists all pods, services, and ingress
- Verifies resources are running

**Output example:**
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-7d4f8c9b5d-abc12    1/1     Running   0          30s
backend-7d4f8c9b5d-def34    1/1     Running   0          30s
frontend-6b8f7c4a3e-ghi56   1/1     Running   0          25s
frontend-6b8f7c4a3e-jkl78   1/1     Running   0          25s
mysql-0                     1/1     Running   0          5m
```

**What to look for:**
- `READY` column shows `1/1` (container ready)
- `STATUS` shows `Running`
- No `CrashLoopBackOff` or `Error` status

**Duration:** ~5-10 seconds

---

## 🔄 Section 3: Post Actions

```groovy
post {
    always {
        archiveArtifacts artifacts: 'trivy-*.html', allowEmptyArchive: true
        cleanWs()
    }
    success {
        echo 'Pipeline completed successfully!'
    }
    failure {
        echo 'Pipeline failed. Check logs for details.'
    }
}
```

**What it does:**
- Runs after all stages complete (regardless of success/failure)
- Archives security scan reports
- Cleans up workspace

**Actions explained:**

**always** - Runs every time:
- `archiveArtifacts` - Saves Trivy reports for download
- `cleanWs()` - Deletes workspace files to save disk space

**success** - Only if pipeline succeeds:
- Prints success message
- (Can add: Send Slack notification, update status page)

**failure** - Only if pipeline fails:
- Prints failure message
- (Can add: Send alert, create Jira ticket)

---

## 🎯 Complete Pipeline Flow

```
1. Git Checkout (20s)
   ↓
2. Install Dependencies [Parallel] (1-2m)
   ├─ Frontend npm install
   └─ Backend npm install
   ↓
3. SonarQube Analysis (1-2m)
   ↓
4. Quality Gate Check (30s)
   ↓
5. Trivy FS Scan (30-60s)
   ↓
6. Build & Scan Images [Parallel] (3-5m)
   ├─ Build Frontend → Scan Frontend
   └─ Build Backend → Scan Backend
   ↓
7. Push to ECR (2-3m)
   ↓
8. Update K8s Manifests (5s)
   ↓
9. Deploy to EKS (1-2m)
   ↓
10. Verify Deployment (10s)
   ↓
Post: Archive Reports & Cleanup

Total: ~8-12 minutes
```

---

## 🔐 Security Features

The pipeline includes multiple security layers:

1. **Code Quality** - SonarQube analysis
2. **Dependency Scanning** - Trivy filesystem scan
3. **Image Scanning** - Trivy container scan
4. **Secrets Management** - AWS credentials via Jenkins
5. **Private Registry** - ECR instead of public Docker Hub
6. **Least Privilege** - IAM roles with minimal permissions

---

## 🛠️ Customization Options

### Change Deployment Region

```groovy
environment {
    AWS_REGION = 'us-east-1'  // Change this
}
```

### Add Email Notifications

```groovy
post {
    success {
        emailext (
            subject: "Pipeline Success: ${env.JOB_NAME}",
            body: "Build ${env.BUILD_NUMBER} completed successfully",
            to: "team@example.com"
        )
    }
}
```

### Add Slack Notifications

```groovy
post {
    success {
        slackSend (
            color: 'good',
            message: "Pipeline succeeded: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
}
```

### Add Manual Approval

```groovy
stage('Approve Deployment') {
    steps {
        input message: 'Deploy to production?', ok: 'Deploy'
    }
}
```

### Add Rollback on Failure

```groovy
post {
    failure {
        script {
            sh '''
                kubectl rollout undo deployment/backend -n production
                kubectl rollout undo deployment/frontend -n production
            '''
        }
    }
}
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Docker Permission Denied

**Error:** `permission denied while trying to connect to the Docker daemon`

**Solution:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue 2: kubectl Not Found

**Error:** `kubectl: command not found`

**Solution:**
```bash
sudo ln -s /usr/local/bin/kubectl /usr/bin/kubectl
```

### Issue 3: ECR Authentication Failed

**Error:** `no basic auth credentials`

**Solution:**
- Verify AWS credentials in Jenkins
- Check IAM role has ECR permissions
- Ensure region is correct

### Issue 4: Image Pull Error in EKS

**Error:** `Failed to pull image: access denied`

**Solution:**
- Verify EKS node IAM role has ECR read permissions
- Check image name and tag are correct
- Ensure ECR repository exists

### Issue 5: SonarQube Quality Gate Timeout

**Error:** `Timeout waiting for quality gate`

**Solution:**
- Increase timeout value
- Check SonarQube server is accessible
- Verify webhook is configured

---

## 📊 Pipeline Metrics

Track these metrics for pipeline health:

- **Success Rate** - % of successful builds
- **Average Duration** - Time per build
- **Failure Reasons** - Most common errors
- **Security Issues** - Vulnerabilities found
- **Code Quality** - SonarQube ratings

**View in Jenkins:**
- Dashboard → Pipeline → Build History
- Blue Ocean view for visual pipeline

---

## 🎓 Key Concepts Learned

1. **Declarative Pipeline** - Modern Jenkins syntax
2. **Parallel Execution** - Speed up builds
3. **Environment Variables** - Centralized configuration
4. **Credentials Management** - Secure secrets handling
5. **Docker Multi-stage** - Efficient image building
6. **GitOps** - Infrastructure as code
7. **Rolling Updates** - Zero-downtime deployments
8. **Security Scanning** - Shift-left security

---

## 📚 Additional Resources

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)

---

## 🎯 Next Steps

Now that you understand the pipeline:

1. Customize it for your needs
2. Add more stages (testing, staging environment)
3. Implement advanced features (canary deployments, blue-green)
4. Set up monitoring and alerting
5. Document your changes

---

**✅ You now understand every line of the Jenkins pipeline!** Ready to build your own CI/CD workflows.
