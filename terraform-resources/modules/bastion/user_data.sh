#!/bin/bash
set -e

# Update system
yum update -y

# Install essential tools
yum install -y \
    git \
    jq \
    wget \
    unzip \
    vim \
    htop

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure kubectl for EKS
mkdir -p /home/ec2-user/.kube
aws eks update-kubeconfig --name ${cluster_name} --region ${aws_region} --kubeconfig /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube

# Add kubectl completion
echo 'source <(kubectl completion bash)' >> /home/ec2-user/.bashrc
echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'complete -F __start_kubectl k' >> /home/ec2-user/.bashrc

# Install k9s (Kubernetes CLI UI)
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz

echo "Bastion host setup complete!" > /var/log/user-data.log
