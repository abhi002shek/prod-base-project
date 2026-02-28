# 🎯 Production Monitoring Guide - Like a King! 👑

## 🚀 Quick Start

### Access Grafana (Main Dashboard)
```bash
# Terminal 1: Start port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: admin123
```

### Access Prometheus (Raw Metrics)
```bash
# Terminal 2: Start port-forward
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-stack-prometheus 9090:9090

# Open browser: http://localhost:9090
```

---

## 📊 Pre-Built Dashboards (Import in Grafana)

Go to **Dashboards → Import** and enter these IDs:

| Dashboard | ID | What It Shows |
|-----------|-----|---------------|
| **Kubernetes Cluster** | 15757 | Complete cluster overview, CPU, Memory, Network |
| **Kubernetes Pods** | 6417 | Pod-level metrics, restarts, status |
| **Node Metrics** | 1860 | Node CPU, Memory, Disk, Network |
| **MySQL Performance** | 7362 | MySQL queries, connections, performance |
| **Nginx Ingress** | 9614 | HTTP traffic, response times, errors |

---

## 🔍 Key Metrics to Monitor

### 1. **Application Health**
```promql
# Pod Status (Should be 1 for Running)
kube_pod_status_phase{namespace="production"}

# Pod Restart Count
kube_pod_container_status_restarts_total{namespace="production"}

# Pods Ready vs Total
kube_deployment_status_replicas_available{namespace="production"}
```

### 2. **Resource Usage**
```promql
# CPU Usage by Pod
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m])) by (pod)

# Memory Usage by Pod
sum(container_memory_usage_bytes{namespace="production"}) by (pod)

# Disk Usage
sum(container_fs_usage_bytes{namespace="production"}) by (pod)
```

### 3. **Network Traffic**
```promql
# Incoming Traffic
rate(container_network_receive_bytes_total{namespace="production"}[5m])

# Outgoing Traffic
rate(container_network_transmit_bytes_total{namespace="production"}[5m])
```

### 4. **Database Metrics**
```promql
# MySQL Connections
mysql_global_status_threads_connected

# MySQL Queries per Second
rate(mysql_global_status_queries[5m])
```

---

## 🚨 Active Alerts

Your cluster has these alerts configured:

| Alert | Trigger | Severity |
|-------|---------|----------|
| **PodDown** | Pod not running for 5min | Critical |
| **HighCPUUsage** | CPU > 80% for 10min | Warning |
| **HighMemoryUsage** | Memory > 90% for 10min | Warning |
| **PodRestartingTooOften** | Restarts in last 15min | Warning |
| **MySQLDown** | MySQL pod down for 2min | Critical |

View active alerts: http://localhost:9090/alerts (after port-forward)

---

## 💻 CLI Monitoring Commands

### Real-Time Pod Monitoring
```bash
# Watch pods (auto-refresh every 2s)
watch kubectl get pods -n production

# Resource usage (requires metrics-server)
kubectl top pods -n production
kubectl top nodes

# Live logs
kubectl logs -f deployment/frontend -n production
kubectl logs -f deployment/backend -n production
kubectl logs -f mysql-0 -n production
```

### Check Events
```bash
# Recent events
kubectl get events -n production --sort-by='.lastTimestamp' | tail -20

# Watch events live
kubectl get events -n production --watch
```

### Detailed Pod Info
```bash
# Full pod details
kubectl describe pod <pod-name> -n production

# Pod YAML
kubectl get pod <pod-name> -n production -o yaml
```

---

## 📈 Grafana Dashboard Creation

### Create Custom Dashboard:

1. **Go to Grafana** → Dashboards → New Dashboard
2. **Add Panel** → Select visualization type
3. **Enter PromQL query** (examples below)
4. **Save Dashboard**

### Example Panels:

**Panel 1: Frontend Pod Count**
```promql
count(kube_pod_info{namespace="production",pod=~"frontend.*"})
```

**Panel 2: Backend Response Time** (if metrics exposed)
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="production"}[5m]))
```

**Panel 3: Error Rate**
```promql
rate(http_requests_total{namespace="production",status=~"5.."}[5m])
```

---

## 🎨 Visualization Types

| Metric Type | Best Visualization |
|-------------|-------------------|
| Pod Count | **Stat** or **Gauge** |
| CPU/Memory Usage | **Time Series Graph** |
| Pod Status | **State Timeline** |
| Request Rate | **Bar Chart** or **Graph** |
| Error Count | **Stat** with thresholds |
| Latency | **Heatmap** |

---

## 🔔 Alert Notifications (Optional Setup)

### Slack Integration:
```yaml
# Edit AlertManager config
kubectl edit secret alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring

# Add Slack webhook
receivers:
- name: 'slack'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts'
```

### Email Integration:
```yaml
receivers:
- name: 'email'
  email_configs:
  - to: 'your-email@example.com'
    from: 'alertmanager@example.com'
    smarthost: 'smtp.gmail.com:587'
    auth_username: 'your-email@gmail.com'
    auth_password: 'your-app-password'
```

---

## 📊 Monitoring Checklist

### Daily:
- [ ] Check Grafana dashboards for anomalies
- [ ] Review active alerts
- [ ] Check pod restart counts
- [ ] Verify all pods are running

### Weekly:
- [ ] Review resource usage trends
- [ ] Check disk space on nodes
- [ ] Review application logs for errors
- [ ] Test alert notifications

### Monthly:
- [ ] Review and update alert thresholds
- [ ] Archive old metrics (if needed)
- [ ] Update Grafana dashboards
- [ ] Review capacity planning

---

## 🎯 Pro Tips

1. **Set up multiple screens**: Grafana on one, Prometheus on another
2. **Create role-based dashboards**: Dev team, Ops team, Management
3. **Use variables in dashboards**: Switch between namespaces/pods easily
4. **Set up annotations**: Mark deployments on graphs
5. **Export dashboards**: Save as JSON for backup

---

## 🆘 Troubleshooting

### Grafana not showing data?
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-stack-prometheus 9090:9090
# Open: http://localhost:9090/targets
# All should be "UP"
```

### Metrics missing?
```bash
# Check ServiceMonitors
kubectl get servicemonitors -n production

# Check if Prometheus is scraping
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus
```

### Alerts not firing?
```bash
# Check PrometheusRules
kubectl get prometheusrules -n monitoring

# Check AlertManager
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```

---

## 📚 Resources

- Prometheus Query Language: https://prometheus.io/docs/prometheus/latest/querying/basics/
- Grafana Dashboards: https://grafana.com/grafana/dashboards/
- Kubernetes Metrics: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

---

**You're now monitoring like a production king! 👑**
