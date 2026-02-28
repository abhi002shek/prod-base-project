# AI Image Generation Prompt - AWS Infrastructure Architecture

Copy and paste this prompt into any AI image generator (DALL-E, Midjourney, Stable Diffusion, etc.)

---

## 🎨 PROMPT FOR AI IMAGE GENERATION:

```
Create a professional AWS cloud infrastructure architecture diagram with the following components:

LAYOUT:
- Clean, modern technical diagram style
- Use official AWS service icons and colors
- Show clear connections between components
- Include labels for each service

COMPONENTS TO INCLUDE:

1. VPC (Virtual Private Cloud) - Large container encompassing everything
   - Label: "VPC 10.0.0.0/16"
   - Spans across 2 Availability Zones (AZ-1 and AZ-2)

2. PUBLIC SUBNETS (in both AZs):
   - Internet Gateway at the top
   - Application Load Balancer (ALB)
   - NAT Gateways (one in each AZ)
   - Bastion Host (in AZ-1)
   - Label: "Public Subnet 10.0.1.0/24" and "10.0.2.0/24"

3. PRIVATE SUBNETS (in both AZs):
   - EKS Cluster with Kubernetes logo
   - Multiple EC2 instances (worker nodes) inside EKS
   - Show pods: Frontend (React), Backend (Node.js), MySQL
   - Label: "Private Subnet 10.0.11.0/24" and "10.0.12.0/24"

4. DATABASE SUBNETS (in both AZs):
   - RDS PostgreSQL (Primary in AZ-1, Standby in AZ-2) - Optional, not used by app
   - Application uses MySQL running in Kubernetes instead
   - Label: "DB Subnet 10.0.21.0/24" and "10.0.22.0/24"

5. EXTERNAL COMPONENTS:
   - Users/Internet at the top
   - ECR (Elastic Container Registry) on the side
   - CloudWatch for monitoring
   - KMS for encryption
   - S3 bucket for Terraform state

6. CONNECTIONS:
   - Arrow from Internet → Internet Gateway → ALB
   - Arrow from ALB → EKS Pods
   - Arrow from EKS Backend → RDS Database
   - Arrow from NAT Gateway → Internet (for outbound traffic)
   - Dotted lines showing security group boundaries

7. CI/CD SECTION (separate box):
   - Jenkins server (EC2)
   - SonarQube server (EC2)
   - Arrows showing: GitHub → Jenkins → ECR → EKS

COLOR SCHEME:
- Use AWS orange/blue color palette
- Public subnets: Light blue
- Private subnets: Light green
- Database subnets: Light purple
- Security groups: Dotted red lines

STYLE:
- Professional technical diagram
- Clean lines and clear labels
- Modern, minimalist design
- High contrast for readability
- Include AWS logo in corner
```

---

## 🎨 ALTERNATIVE SIMPLER PROMPT:

```
Create an AWS cloud architecture diagram showing:
- VPC with 2 availability zones
- Public subnets with ALB and NAT gateways
- Private subnets with EKS cluster running Kubernetes pods (Frontend, Backend, MySQL)
- Database subnets (optional RDS, not used by app)
- External: Internet Gateway, users, Jenkins CI/CD
- Use official AWS icons and colors
- Professional technical diagram style
- Show arrows for traffic flow
- Label all components clearly
- Note: Application uses MySQL in Kubernetes, not RDS
```

---

## 🎨 PROMPT FOR SPECIFIC AI TOOLS:

### For DALL-E 3:
```
Technical architecture diagram of AWS cloud infrastructure. Show a VPC containing: Internet Gateway at top, Application Load Balancer in public subnet, EKS Kubernetes cluster with pods (Frontend, Backend, MySQL) in private subnet. Include NAT Gateway, Bastion host, and Jenkins CI/CD pipeline. Use AWS official colors (orange and blue). Professional, clean, technical style with clear labels and connection arrows. Isometric view. Note: MySQL runs in Kubernetes pods.
```

### For Midjourney:
```
AWS cloud architecture diagram, technical illustration, VPC with multiple subnets, EKS cluster with MySQL pods, ALB load balancer, clean professional style, AWS orange and blue colors, labeled components, connection arrows, isometric view, white background, high detail --ar 16:9 --style technical
```

### For Stable Diffusion:
```
professional AWS cloud infrastructure architecture diagram, VPC network topology, EKS kubernetes cluster, RDS database, application load balancer, technical illustration, clean lines, AWS official colors, labeled components, white background, high quality, detailed
```

---

## 📊 WHAT THE DIAGRAM SHOULD SHOW:

### Traffic Flow:
1. User → Internet → Internet Gateway
2. Internet Gateway → ALB (in public subnet)
3. ALB → Frontend Pods (in EKS private subnet)
4. Frontend → Backend Pods
5. Backend → RDS Database (in DB subnet)
6. Pods → NAT Gateway → Internet (for updates)

### CI/CD Flow:
1. Developer → GitHub
2. GitHub → Jenkins (webhook)
3. Jenkins → Build & Test
4. Jenkins → Push to ECR
5. Jenkins → Deploy to EKS
6. EKS → Pull images from ECR

### Security Layers:
- Security Groups (dotted lines around each component)
- Private subnets (no direct internet access)
- Bastion host (for SSH access)
- KMS encryption (shown with lock icons)

---

## 🎯 KEY ELEMENTS TO EMPHASIZE:

1. **Multi-AZ Setup** - Show redundancy across 2 availability zones
2. **3-Tier Architecture** - Frontend, Backend, Database clearly separated
3. **Security** - Private subnets, security groups, bastion host
4. **Scalability** - Multiple pods in EKS, auto-scaling groups
5. **High Availability** - RDS Multi-AZ, multiple NAT gateways
6. **CI/CD Integration** - Jenkins pipeline connected to infrastructure

---

## 💡 TIPS FOR BEST RESULTS:

1. **Try Multiple Tools**: Different AI tools produce different styles
2. **Iterate**: Generate multiple versions and pick the best
3. **Refine**: Add more specific details if first result isn't perfect
4. **Combine**: You might need to combine elements from multiple generations
5. **Edit**: Use tools like Figma or draw.io to add final touches

---

## 🛠️ ALTERNATIVE: Create Your Own Diagram

If AI generation doesn't work well, use these free tools:

1. **draw.io** (diagrams.net)
   - Free, web-based
   - Has AWS icon library
   - Easy to use

2. **Lucidchart**
   - Professional diagrams
   - AWS shapes included
   - Free tier available

3. **CloudCraft**
   - Specifically for AWS
   - 3D isometric view
   - Free tier available

4. **Excalidraw**
   - Hand-drawn style
   - Simple and clean
   - Completely free

---

## 📝 COMPONENTS LIST FOR MANUAL CREATION:

```
AWS Services to Include:
☐ VPC
☐ Internet Gateway
☐ Application Load Balancer
☐ NAT Gateway (x2)
☐ Bastion Host
☐ EKS Cluster
☐ EC2 Instances (worker nodes)
☐ RDS PostgreSQL (Primary + Standby)
☐ ECR (Container Registry)
☐ S3 (Terraform state)
☐ CloudWatch
☐ KMS
☐ Jenkins EC2
☐ SonarQube EC2

Kubernetes Components:
☐ Frontend Pods (React)
☐ Backend Pods (Node.js)
☐ MySQL StatefulSet
☐ Services
☐ Ingress
☐ HPA (Horizontal Pod Autoscaler)

Network Components:
☐ Public Subnets (x2)
☐ Private Subnets (x2)
☐ Database Subnets (x2)
☐ Route Tables
☐ Security Groups
```

---

## 🎨 EXAMPLE DESCRIPTION FOR REFERENCE:

Your infrastructure looks like this:

```
                    [Users/Internet]
                           |
                    [Internet Gateway]
                           |
        ┌──────────────────┴──────────────────┐
        |              VPC                    |
        |  ┌─────────────────────────────┐   |
        |  |    Public Subnets (AZ1+2)   |   |
        |  |  [ALB] [NAT-GW] [Bastion]   |   |
        |  └──────────┬──────────────────┘   |
        |             |                       |
        |  ┌──────────▼──────────────────┐   |
        |  |   Private Subnets (AZ1+2)   |   |
        |  |      [EKS Cluster]          |   |
        |  |   ┌─────────────────┐       |   |
        |  |   | Frontend Pods   |       |   |
        |  |   | Backend Pods    |       |   |
        |  |   | MySQL Pod       |       |   |
        |  |   └────────┬────────┘       |   |
        |  └────────────┼────────────────┘   |
        |               |                     |
        |  ┌────────────▼────────────────┐   |
        |  |   Database Subnets (AZ1+2)  |   |
        |  |   [RDS Primary] [Standby]   |   |
        |  └─────────────────────────────┘   |
        └─────────────────────────────────────┘

    [Jenkins] → [ECR] → [EKS]
```

---

**🎨 Use any of these prompts to generate your infrastructure diagram!**
