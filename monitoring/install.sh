#!/bin/bash
set -e

echo "🚀 Installing Monitoring Stack..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Add Helm repos
echo -e "${YELLOW}Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
echo -e "${YELLOW}Creating monitoring namespace...${NC}"
kubectl apply -f namespace.yaml

# Install Prometheus stack
echo -e "${YELLOW}Installing kube-prometheus-stack...${NC}"
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml \
  --wait

# Wait for pods
echo -e "${YELLOW}Waiting for pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s

# Get Grafana password
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "📊 Grafana Access:"
echo "  Username: admin"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "🔗 Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo "  Then visit: http://localhost:3000"
echo ""
echo "🔗 Access Prometheus:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo "🔗 Access AlertManager:"
echo "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093"
echo "  Then visit: http://localhost:9093"
echo ""
echo "📝 For production access via ALB:"
echo "  kubectl apply -f grafana-ingress.yaml"
echo ""
