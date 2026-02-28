# Production Monitoring Stack

## Overview

Complete monitoring solution using Prometheus and Grafana for EKS cluster and application monitoring.

### Components

1. **Prometheus** - Metrics collection and storage
2. **Grafana** - Visualization and dashboards
3. **Prometheus Operator** - Kubernetes-native Prometheus management
4. **Node Exporter** - Hardware and OS metrics
5. **Kube State Metrics** - Kubernetes object metrics
6. **AlertManager** - Alert routing and management

---

## Quick Install

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack (includes everything)
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml

# Verify installation
kubectl get pods -n monitoring
```

---

## Installation Steps

### Step 1: Create Namespace

```bash
kubectl apply -f namespace.yaml
```

### Step 2: Install Prometheus Stack

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml \
  --wait
```

### Step 3: Access Grafana

```bash
# Get Grafana password
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Port forward to access locally
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Access: http://localhost:3000
# Username: admin
# Password: (from above command)
```

### Step 4: Access Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Access: http://localhost:9090
```

### Step 5: Access AlertManager

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Access: http://localhost:9093
```

---

## Production Access (via ALB)

For production, expose Grafana via ALB:

```bash
kubectl apply -f grafana-ingress.yaml
```

Get ALB URL:
```bash
kubectl get ingress grafana-ingress -n monitoring
```

---

## Pre-configured Dashboards

Grafana comes with these dashboards:

1. **Kubernetes / Compute Resources / Cluster** - Overall cluster metrics
2. **Kubernetes / Compute Resources / Namespace (Pods)** - Per-namespace metrics
3. **Kubernetes / Compute Resources / Node (Pods)** - Per-node metrics
4. **Kubernetes / Compute Resources / Pod** - Per-pod metrics
5. **Node Exporter / Nodes** - Hardware metrics
6. **Prometheus / Overview** - Prometheus stats

---

## Custom Application Monitoring

### Add ServiceMonitor for Backend

```bash
kubectl apply -f servicemonitor-backend.yaml
```

### Add ServiceMonitor for Frontend

```bash
kubectl apply -f servicemonitor-frontend.yaml
```

---

## Alerts

Pre-configured alerts include:

- Node down
- High CPU usage
- High memory usage
- Pod crash looping
- Persistent volume issues
- API server errors

Configure Slack/Email notifications:

```bash
kubectl apply -f alertmanager-config.yaml
```

---

## Monitoring Metrics

### Cluster Metrics
- Node CPU, Memory, Disk usage
- Pod resource usage
- Network traffic
- API server performance

### Application Metrics
- HTTP request rate
- Response times
- Error rates
- Database connections

### Infrastructure Metrics
- EKS control plane
- Load balancer metrics
- RDS metrics (via CloudWatch)

---

## Troubleshooting

### Prometheus not scraping targets

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090/targets
```

### Grafana dashboards not loading

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana

# Restart Grafana
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring
```

---

## Retention and Storage

Default retention: 10 days

To increase:

```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

---

## Cleanup

```bash
helm uninstall kube-prometheus-stack -n monitoring
kubectl delete namespace monitoring
```

---

## Cost Optimization

- Default setup: ~$30-50/month (storage + compute)
- With persistent storage (50Gi): ~$5/month additional
- Total monitoring cost: ~$35-55/month

---

## Next Steps

1. Configure AlertManager for notifications
2. Create custom dashboards for your application
3. Set up log aggregation (ELK/Loki)
4. Enable long-term storage (Thanos)
