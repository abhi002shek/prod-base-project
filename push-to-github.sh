#!/bin/bash

# GitHub Push Script - Production Base Project
# This script helps you push the project to GitHub cleanly

set -e  # Exit on error

echo "🚀 Production Base Project - GitHub Push Script"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install git first.${NC}"
    exit 1
fi

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${YELLOW}⚠️  Not a git repository. Initializing...${NC}"
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
fi

# Check for sensitive files
echo ""
echo "🔍 Checking for sensitive files..."
SENSITIVE_FILES=(
    "terraform.tfvars"
    "*.pem"
    "*.key"
    ".env"
    "*secret*"
    "*password*"
)

FOUND_SENSITIVE=false
for pattern in "${SENSITIVE_FILES[@]}"; do
    if find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" | grep -q .; then
        echo -e "${RED}⚠️  Found sensitive files matching: $pattern${NC}"
        find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*"
        FOUND_SENSITIVE=true
    fi
done

if [ "$FOUND_SENSITIVE" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Sensitive files detected!${NC}"
    echo "These files should NOT be committed to GitHub."
    echo "They are already in .gitignore, but please verify."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo -e "${GREEN}✅ No sensitive files will be committed${NC}"

# Update Jenkinsfile with placeholder
echo ""
echo "📝 Updating Jenkinsfile with placeholders..."
if [ -f "Jenkinsfile" ]; then
    sed -i.bak "s/AWS_ACCOUNT_ID = '[0-9]*'/AWS_ACCOUNT_ID = '<YOUR_AWS_ACCOUNT_ID>'/g" Jenkinsfile
    sed -i.bak "s/AWS_REGION = '[^']*'/AWS_REGION = '<YOUR_AWS_REGION>'/g" Jenkinsfile
    rm -f Jenkinsfile.bak
    echo -e "${GREEN}✅ Jenkinsfile updated with placeholders${NC}"
fi

# Update K8s manifests with placeholders
echo ""
echo "📝 Updating Kubernetes manifests with placeholders..."
if [ -d "application/k8s-prod" ]; then
    find application/k8s-prod -name "*.yaml" -exec sed -i.bak 's/[0-9]\{12\}\.dkr\.ecr\.[^.]*\.amazonaws\.com/<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/g' {} \;
    find application/k8s-prod -name "*.bak" -delete
    echo -e "${GREEN}✅ Kubernetes manifests updated with placeholders${NC}"
fi

# Check git status
echo ""
echo "📊 Current git status:"
git status --short

# Add all files
echo ""
echo "➕ Adding files to git..."
git add .

# Show what will be committed
echo ""
echo "📋 Files to be committed:"
git status --short

# Commit
echo ""
read -p "Enter commit message (or press Enter for default): " COMMIT_MSG
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Production-ready AWS EKS infrastructure with CI/CD pipeline"
fi

git commit -m "$COMMIT_MSG" || echo "Nothing to commit"

# Check if remote exists
if git remote | grep -q "origin"; then
    echo ""
    echo "🔗 Remote 'origin' already exists:"
    git remote -v
    echo ""
    read -p "Do you want to update the remote URL? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter new GitHub repository URL: " REPO_URL
        git remote set-url origin "$REPO_URL"
        echo -e "${GREEN}✅ Remote URL updated${NC}"
    fi
else
    echo ""
    read -p "Enter your GitHub repository URL (e.g., https://github.com/username/repo.git): " REPO_URL
    if [ -z "$REPO_URL" ]; then
        echo -e "${RED}❌ Repository URL is required${NC}"
        exit 1
    fi
    git remote add origin "$REPO_URL"
    echo -e "${GREEN}✅ Remote 'origin' added${NC}"
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="main"
    git branch -M main
fi

# Push to GitHub
echo ""
echo "🚀 Pushing to GitHub..."
read -p "Push to branch '$CURRENT_BRANCH'? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git push -u origin "$CURRENT_BRANCH"
    echo ""
    echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"
    echo ""
    echo "🎉 Your project is now on GitHub!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Update README.md with your GitHub username"
    echo "2. Add repository URL to LinkedIn post"
    echo "3. Update Jenkinsfile with your AWS account ID"
    echo "4. Update K8s manifests with your ECR URLs"
    echo "5. Create GitHub releases for versions"
    echo ""
    echo "🔗 Repository: $(git remote get-url origin)"
else
    echo "Push cancelled."
fi

echo ""
echo "✨ Done!"
