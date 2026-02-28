# Monitoring Guide - Prometheus & Grafana

Complete guide for setting up and using monitoring stack for your EKS cluster and applications.

---

## 🎯 Overview

This monitoring stack provides:
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards
- **AlertManager** - Alert routing and notifications
- **Node Exporter** - Node-level metrics
- **Kube State Metrics** - Kubernetes object metrics

---

## 📦 Installation

### Quick Install

```bash
cd monitoring
./install.sh
```

### Manual Installation

#### Step 1: Add Helm Repository

```bash
# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### Step 2: Create Namespace

```bash
kubectl apply -f namespace.yaml
```

Or manually:
```bash
kubectl create namespace monitoring
```

#### Step 3: Install Prometheus Stack

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values-prometheus.yaml \
  --wait
```

**Installation takes:** ~3-5 minutes

#### Step 4: Verify Installation

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Expected pods:
# - alertmanager-xxx
# - prometheus-xxx
# - grafana-xxx
# - kube-state-metrics-xxx
# - prometheus-node-exporter-xxx (one per node)
# - prometheus-operator-xxx
```

---

## 🔐 Access Dashboards

### Option 1: Port Forwarding (Development)

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```
Access: http://localhost:3000

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```
Access: http://localhost:9090

**AlertManager:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```
Access: http://localhost:9093

### Option 2: Ingress (Production)

**Deploy Grafana Ingress:**
```bash
kubectl apply -f grafana-ingress.yaml
```

**Get ALB URL:**
```bash
kubectl get ingress grafana-ingress -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## 🔑 Default Credentials

### Grafana

**Username:** `admin`

**Get Password:**
```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

**Change Password:**
1. Login to Grafana
2. Click profile icon → Change Password
3. Enter new password

---

## 📊 Pre-configured Dashboards

Grafana comes with 15+ pre-built dashboards:

### Cluster Overview
- **Kubernetes / Compute Resources / Cluster**
  - Total CPU/Memory usage
  - Pod count
  - Node status

### Node Metrics
- **Kubernetes / Compute Resources / Node**
  - Per-node CPU/Memory
  - Disk I/O
  - Network traffic

### Pod Metrics
- **Kubernetes / Compute Resources / Pod**
  - Container resource usage
  - Restart count
  - Network I/O

### Namespace Resources
- **Kubernetes / Compute Resources / Namespace**
  - Resource usage by namespace
  - Pod distribution

### Persistent Volumes
- **Kubernetes / Persistent Volumes**
  - PV/PVC status
  - Storage usage

---

## 🎨 Import Custom Dashboard

### Import Production Dashboard

```bash
# Dashboard is in monitoring/production-dashboard.json
```

**Via Grafana UI:**
1. Login to Grafana
2. Click "+" → Import
3. Upload `production-dashboard.json`
4. Select Prometheus data source
5. Click Import

**Via kubectl:**
```bash
kubectl create configmap production-dashboard \
  --from-file=production-dashboard.json \
  -n monitoring

kubectl label configmap production-dashboard \
  grafana_dashboard=1 \
  -n monitoring
```

---

## 📈 Monitor Your Application

### Step 1: Add ServiceMonitor

ServiceMonitor tells Prometheus to scrape your application metrics.

**Frontend ServiceMonitor:**
```bash
kubectl apply -f servicemonitor-frontend.yaml
```

**Backend ServiceMonitor:**
```bash
kubectl apply -f servicemonitor-backend.yaml
```

### Step 2: Expose Metrics in Application

**Node.js Example (Backend):**

Install prom-client:
```bash
npm install prom-client
```

Add to your app:
```javascript
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### Step 3: Verify Metrics Collection

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n production

# Check Prometheus targets
# Access Prometheus UI → Status → Targets
# Look for your application endpoints
```

---

## 🚨 Configure Alerts

### Step 1: Update AlertManager Config

Edit `alertmanager-config.yaml`:

**Slack Notifications:**
```yaml
global:
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#alerts'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Email Notifications:**
```yaml
receivers:
- name: 'email-notifications'
  email_configs:
  - to: 'team@example.com'
    from: 'alerts@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'alerts@example.com'
    auth_password: 'your-app-password'
```

### Step 2: Apply Configuration

```bash
kubectl apply -f alertmanager-config.yaml
```

### Step 3: Reload AlertManager

```bash
kubectl rollout restart statefulset/alertmanager-kube-prometheus-stack-alertmanager -n monitoring
```

---

## 🔔 Default Alerts

The stack includes 100+ pre-configured alerts:

### Critical Alerts
- **KubePodCrashLooping** - Pod restarting frequently
- **KubeNodeNotReady** - Node is down
- **KubePodNotReady** - Pod not ready for 15+ minutes
- **KubeDeploymentReplicasMismatch** - Deployment replicas mismatch

### Warning Alerts
- **KubeCPUOvercommit** - CPU overcommitted
- **KubeMemoryOvercommit** - Memory overcommitted
- **KubePersistentVolumeFillingUp** - PV filling up

### Info Alerts
- **KubeVersionMismatch** - Different Kubernetes versions
- **KubeClientCertificateExpiration** - Cert expiring soon

---

## 📊 Useful Queries

### PromQL Examples

**CPU Usage by Pod:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m])) by (pod)
```

**Memory Usage by Pod:**
```promql
sum(container_memory_working_set_bytes{namespace="production"}) by (pod)
```

**HTTP Request Rate:**
```promql
sum(rate(http_requests_total{namespace="production"}[5m])) by (service)
```

**Pod Restart Count:**
```promql
sum(kube_pod_container_status_restarts_total{namespace="production"}) by (pod)
```

**Available Disk Space:**
```promql
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100
```

**Network Traffic:**
```promql
sum(rate(container_network_receive_bytes_total{namespace="production"}[5m])) by (pod)
```

---

## 🎯 Create Custom Dashboard

### Step 1: Create New Dashboard

1. Grafana → "+" → Dashboard
2. Add Panel
3. Select visualization type (Graph, Gauge, Table, etc.)

### Step 2: Add Query

Example - Backend Response Time:
```promql
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket{service="backend"}[5m])) by (le)
)
```

### Step 3: Configure Panel

- **Title:** Backend 95th Percentile Response Time
- **Unit:** seconds (s)
- **Legend:** Show
- **Thresholds:** 
  - Green: < 0.5s
  - Yellow: 0.5s - 1s
  - Red: > 1s

### Step 4: Save Dashboard

- Click Save icon
- Name: "Production Application Metrics"
- Folder: General
- Save

---

## 🔍 Troubleshooting

### Issue 1: Prometheus Not Scraping Targets

**Check ServiceMonitor:**
```bash
kubectl get servicemonitor -n production
kubectl describe servicemonitor backend-monitor -n production
```

**Check Prometheus Config:**
```bash
kubectl get secret prometheus-kube-prometheus-stack-prometheus -n monitoring -o yaml
```

**Check Prometheus Logs:**
```bash
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0
```

### Issue 2: Grafana Can't Connect to Prometheus

**Verify Data Source:**
1. Grafana → Configuration → Data Sources
2. Click Prometheus
3. URL should be: `http://kube-prometheus-stack-prometheus:9090`
4. Click "Save & Test"

### Issue 3: No Metrics Showing

**Check Metrics Server:**
```bash
kubectl get deployment metrics-server -n kube-system
```

**Install if missing:**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Issue 4: AlertManager Not Sending Alerts

**Test Alert:**
```bash
# Create test alert
kubectl run test-alert --image=busybox --restart=Never -- /bin/sh -c "exit 1"
```

**Check AlertManager Logs:**
```bash
kubectl logs -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0
```

**Verify Configuration:**
```bash
kubectl get secret alertmanager-kube-prometheus-stack-alertmanager -n monitoring -o yaml
```

---

## 📊 Monitoring Best Practices

### 1. Set Appropriate Retention

```yaml
# In values-prometheus.yaml
prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: "50GB"
```

### 2. Use Recording Rules

For frequently used queries:
```yaml
groups:
- name: application_rules
  interval: 30s
  rules:
  - record: job:http_requests:rate5m
    expr: sum(rate(http_requests_total[5m])) by (job)
```

### 3. Configure Resource Limits

```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
```

### 4. Enable Persistent Storage

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
```

### 5. Regular Backups

```bash
# Backup Grafana dashboards
kubectl get configmap -n monitoring -l grafana_dashboard=1 -o yaml > grafana-dashboards-backup.yaml

# Backup Prometheus data
kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -- tar czf /tmp/prometheus-backup.tar.gz /prometheus
kubectl cp monitoring/prometheus-kube-prometheus-stack-prometheus-0:/tmp/prometheus-backup.tar.gz ./prometheus-backup.tar.gz
```

---

## 📈 Performance Optimization

### Reduce Cardinality

Avoid high-cardinality labels:
```yaml
# Bad - user_id creates millions of series
http_requests_total{user_id="12345"}

# Good - use aggregated metrics
http_requests_total{endpoint="/api/users"}
```

### Optimize Scrape Intervals

```yaml
# In ServiceMonitor
spec:
  endpoints:
  - interval: 30s  # Default: 30s
    scrapeTimeout: 10s
```

### Use Federation for Large Clusters

```yaml
# Central Prometheus scrapes from regional Prometheus
- job_name: 'federate'
  scrape_interval: 15s
  honor_labels: true
  metrics_path: '/federate'
  params:
    'match[]':
      - '{job="kubernetes-pods"}'
  static_configs:
    - targets:
      - 'prometheus-region1:9090'
      - 'prometheus-region2:9090'
```

---

## 🧹 Cleanup

### Uninstall Monitoring Stack

```bash
# Uninstall Helm release
helm uninstall kube-prometheus-stack -n monitoring

# Delete namespace
kubectl delete namespace monitoring

# Delete CRDs (optional)
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

---

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Awesome Prometheus Alerts](https://awesome-prometheus-alerts.grep.to/)

---

## 🎯 Next Steps

1. **Create Custom Dashboards** for your application
2. **Configure Alerts** for critical metrics
3. **Set up Notifications** (Slack, Email, PagerDuty)
4. **Enable Long-term Storage** with Thanos or Cortex
5. **Implement SLOs** (Service Level Objectives)

---

**✅ Monitoring Stack Ready!** You can now observe your entire infrastructure and applications.
