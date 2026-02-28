# Complete Monitoring Guide

## 📊 Overview

Production-grade monitoring stack for EKS cluster using Prometheus and Grafana.

### What Gets Monitored

**Infrastructure:**
- EKS cluster health
- Node CPU, memory, disk usage
- Network traffic
- Kubernetes API server

**Application:**
- Pod resource usage
- Container metrics
- HTTP request rates
- Response times
- Error rates

**Database:**
- MySQL connections
- Query performance
- Storage usage

---

## 🚀 Quick Install (5 minutes)

```bash
cd monitoring
./install.sh
```

That's it! The script will:
1. Add Helm repositories
2. Create monitoring namespace
3. Install Prometheus + Grafana
4. Display access credentials

---

## 📋 Manual Installation

### Step 1: Add Helm Repositories

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Step 2: Create Namespace

```bash
kubectl apply -f namespace.yaml
```

### Step 3: Configure Values

Edit `values-prometheus.yaml`:

```yaml
grafana:
  adminPassword: "YourStrongPassword123!"  # CHANGE THIS!
```

### Step 4: Install Prometheus Stack

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml \
  --wait
```

This installs:
- ✅ Prometheus (metrics storage)
- ✅ Grafana (visualization)
- ✅ AlertManager (alerting)
- ✅ Node Exporter (node metrics)
- ✅ Kube State Metrics (K8s metrics)
- ✅ Prometheus Operator (management)

### Step 5: Verify Installation

```bash
kubectl get pods -n monitoring

# Expected output:
# NAME                                                   READY   STATUS
# alertmanager-kube-prometheus-stack-alertmanager-0      2/2     Running
# kube-prometheus-stack-grafana-xxx                      3/3     Running
# kube-prometheus-stack-kube-state-metrics-xxx           1/1     Running
# kube-prometheus-stack-operator-xxx                     1/1     Running
# kube-prometheus-stack-prometheus-node-exporter-xxx     1/1     Running
# prometheus-kube-prometheus-stack-prometheus-0          2/2     Running
```

---

## 🔐 Access Monitoring Tools

### Option 1: Port Forwarding (Development)

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Access: http://localhost:3000
# Username: admin
# Password: (get from command below)
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Access: http://localhost:9090
```

**AlertManager:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093

# Access: http://localhost:9093
```

### Option 2: ALB Ingress (Production)

```bash
# Deploy Grafana ingress
kubectl apply -f grafana-ingress.yaml

# Get ALB URL
kubectl get ingress grafana-ingress -n monitoring

# Access via ALB URL
```

**Security Note:** For production, add:
1. SSL certificate
2. IP whitelist
3. Authentication (OAuth, LDAP)

---

## 📈 Pre-configured Dashboards

Grafana includes these dashboards out-of-the-box:

### Cluster Overview
- **Kubernetes / Compute Resources / Cluster**
  - Total CPU/Memory usage
  - Pod count
  - Network I/O

### Namespace Metrics
- **Kubernetes / Compute Resources / Namespace (Pods)**
  - Per-namespace resource usage
  - Pod status
  - Resource quotas

### Node Metrics
- **Kubernetes / Compute Resources / Node (Pods)**
  - Per-node CPU/Memory
  - Disk usage
  - Network traffic

### Pod Metrics
- **Kubernetes / Compute Resources / Pod**
  - Container resource usage
  - Restart count
  - Network stats

### Node Hardware
- **Node Exporter / Nodes**
  - CPU temperature
  - Disk I/O
  - Network interfaces
  - System load

### Prometheus Stats
- **Prometheus / Overview**
  - Scrape duration
  - Target status
  - Storage usage

---

## 🎯 Custom Application Monitoring

### Add Metrics to Your Application

**Backend (Node.js/Express):**

```javascript
// Install: npm install prom-client
const promClient = require('prom-client');

// Create metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

**Frontend (React):**

```javascript
// Use web-vitals for performance metrics
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  // Send to backend which exposes to Prometheus
  fetch('/api/metrics', {
    method: 'POST',
    body: JSON.stringify(metric)
  });
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getFCP(sendToAnalytics);
getLCP(sendToAnalytics);
getTTFB(sendToAnalytics);
```

### Enable ServiceMonitors

```bash
# Monitor backend
kubectl apply -f servicemonitor-backend.yaml

# Monitor frontend
kubectl apply -f servicemonitor-frontend.yaml
```

### Verify Scraping

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# Visit: http://localhost:9090/targets
# Look for your application targets
```

---

## 🚨 Alerting

### Pre-configured Alerts

The stack includes alerts for:

**Critical:**
- Node down
- Pod crash looping
- High memory usage (>90%)
- Persistent volume full
- API server errors

**Warning:**
- High CPU usage (>80%)
- High memory usage (>75%)
- Pod restart count high
- Slow API responses

### Configure Notifications

**Slack Integration:**

1. Create Slack webhook: https://api.slack.com/messaging/webhooks

2. Update `alertmanager-config.yaml`:

```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

receivers:
- name: 'critical'
  slack_configs:
  - channel: '#alerts-critical'
    title: '🚨 Critical Alert'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

3. Apply configuration:

```bash
kubectl apply -f alertmanager-config.yaml
kubectl rollout restart statefulset/alertmanager-kube-prometheus-stack-alertmanager -n monitoring
```

**Email Integration:**

```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@yourdomain.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

receivers:
- name: 'critical'
  email_configs:
  - to: 'team@yourdomain.com'
    headers:
      Subject: 'Critical Alert from EKS Cluster'
```

### Test Alerts

```bash
# Trigger a test alert
kubectl run test-alert --image=busybox --restart=Never -- /bin/sh -c "exit 1"

# Check AlertManager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Visit: http://localhost:9093
```

---

## 📊 Key Metrics to Monitor

### Cluster Health

```promql
# Node CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod count
count(kube_pod_info)

# Failed pods
count(kube_pod_status_phase{phase="Failed"})
```

### Application Performance

```promql
# HTTP request rate
rate(http_requests_total[5m])

# HTTP error rate
rate(http_requests_total{status=~"5.."}[5m])

# Request duration (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Active connections
sum(backend_active_connections)
```

### Database Metrics

```promql
# MySQL connections
mysql_global_status_threads_connected

# Query rate
rate(mysql_global_status_queries[5m])

# Slow queries
rate(mysql_global_status_slow_queries[5m])
```

---

## 🎨 Creating Custom Dashboards

### Import Dashboard

1. Go to Grafana → Dashboards → Import
2. Enter dashboard ID from https://grafana.com/grafana/dashboards/
3. Select Prometheus data source
4. Click Import

**Recommended Dashboards:**

- **315** - Kubernetes cluster monitoring
- **6417** - Kubernetes cluster overview
- **7249** - Kubernetes cluster (Prometheus)
- **1860** - Node Exporter Full

### Create Custom Dashboard

1. Go to Grafana → Dashboards → New Dashboard
2. Add Panel
3. Select Prometheus data source
4. Enter PromQL query
5. Configure visualization
6. Save dashboard

**Example Panel - Pod CPU Usage:**

```promql
sum(rate(container_cpu_usage_seconds_total{namespace="prod"}[5m])) by (pod)
```

---

## 💾 Data Retention & Storage

### Default Configuration

- **Retention:** 15 days
- **Storage:** 50Gi per Prometheus replica
- **Replicas:** 2 (for HA)

### Increase Retention

Edit `values-prometheus.yaml`:

```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    retentionSize: "90GB"
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi
```

Update installation:

```bash
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml
```

### Long-term Storage (Thanos)

For retention > 30 days, use Thanos:

```bash
helm install thanos bitnami/thanos \
  -n monitoring \
  --set query.enabled=true \
  --set bucketweb.enabled=true \
  --set compactor.enabled=true \
  --set storegateway.enabled=true \
  --set objstoreConfig.type=s3 \
  --set objstoreConfig.config.bucket=my-thanos-bucket
```

---

## 🔧 Troubleshooting

### Prometheus not scraping targets

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# Check Prometheus config
kubectl get prometheus -n monitoring -o yaml

# Check targets in Prometheus UI
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090/targets
```

### Grafana dashboards not loading

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f

# Restart Grafana
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring

# Check data source
# Grafana → Configuration → Data Sources → Prometheus → Test
```

### High memory usage

```bash
# Check Prometheus memory
kubectl top pod -n monitoring | grep prometheus

# Reduce retention or increase resources
# Edit values-prometheus.yaml and upgrade
```

### Alerts not firing

```bash
# Check AlertManager logs
kubectl logs -n monitoring statefulset/alertmanager-kube-prometheus-stack-alertmanager -f

# Check alert rules
kubectl get prometheusrule -n monitoring

# Test AlertManager config
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Visit: http://localhost:9093
```

---

## 💰 Cost Estimation

### Monitoring Stack Costs

| Component | Resources | Monthly Cost |
|-----------|-----------|--------------|
| Prometheus (2 replicas) | 2 CPU, 4Gi RAM each | ~$60 |
| Grafana | 200m CPU, 512Mi RAM | ~$10 |
| AlertManager (2 replicas) | 200m CPU, 256Mi RAM each | ~$15 |
| Node Exporter (per node) | 200m CPU, 256Mi RAM | ~$5/node |
| Storage (100Gi) | EBS gp3 | ~$10 |
| **Total** | | **~$100-120/month** |

### Cost Optimization

1. **Reduce retention:** 15d → 7d (saves ~50% storage)
2. **Single replica:** For non-prod (saves ~40%)
3. **Reduce scrape interval:** 30s → 60s (saves ~20% storage)
4. **Use Spot instances:** For monitoring nodes (saves ~70%)

---

## 🔄 Maintenance

### Update Monitoring Stack

```bash
# Update Helm repos
helm repo update

# Upgrade installation
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml
```

### Backup Grafana Dashboards

```bash
# Export all dashboards
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- \
  grafana-cli admin export-dashboard > dashboards-backup.json
```

### Clean Old Data

```bash
# Prometheus automatically cleans based on retention
# To manually trigger cleanup:
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- \
  promtool tsdb clean-tombstones /prometheus
```

---

## 🗑️ Uninstall

```bash
# Delete monitoring stack
helm uninstall kube-prometheus-stack -n monitoring

# Delete namespace (this deletes PVCs too)
kubectl delete namespace monitoring

# Or keep PVCs for later
kubectl delete all --all -n monitoring
```

---

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

---

## ✅ Monitoring Checklist

- [ ] Monitoring stack installed
- [ ] Grafana accessible
- [ ] Prometheus scraping targets
- [ ] Pre-configured dashboards working
- [ ] Custom application metrics added
- [ ] ServiceMonitors created
- [ ] AlertManager configured
- [ ] Notification channels set up
- [ ] Test alerts verified
- [ ] Retention configured
- [ ] Backup strategy defined
- [ ] Team trained on dashboards

---

**Next:** Configure alerts for your specific use case and create custom dashboards for your application metrics.
