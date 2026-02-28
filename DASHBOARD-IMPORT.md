# 🎯 Import Real-Time Production Dashboard

## 📊 Dashboard Includes:

### **Top Row - Quick Stats:**
- Total Nodes
- Total Pods in Production
- Running Pods Count
- Pod Restarts (Last Hour)

### **Row 2 - Node Metrics:**
- Node CPU Usage (%)
- Node Memory Usage (%)

### **Row 3 - Pod Metrics:**
- Pod CPU Usage (by pod)
- Pod Memory Usage (by pod)

### **Row 4 - Network:**
- Network Traffic Received (KB/s)
- Network Traffic Transmitted (KB/s)

### **Row 5 - Pod Details:**
- Pod Status Table (Name, Node, IP)

### **Row 6 - Additional:**
- Disk Usage by Node (%)
- Container Restart Rate

---

## 🚀 How to Import:

### **Method 1: Import JSON File**

1. **Start Grafana:**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   ```

2. **Open Grafana:** http://localhost:3000
   - Username: `admin`
   - Password: `admin123`

3. **Import Dashboard:**
   - Click **"+"** (left sidebar) → **Import**
   - Click **"Upload JSON file"**
   - Select: `/Users/abhishek/Downloads/terraform/Prod-base-project/production-dashboard.json`
   - Click **"Load"**
   - Select **Prometheus** as data source
   - Click **"Import"**

### **Method 2: Use Pre-Built Dashboards**

Import these popular dashboards by ID:

| Dashboard | ID | Description |
|-----------|-----|-------------|
| **Kubernetes Cluster Monitoring** | 15757 | Complete cluster overview |
| **Kubernetes / Views / Pods** | 15760 | Detailed pod metrics |
| **Node Exporter Full** | 1860 | Complete node metrics |
| **Kubernetes Cluster (Prometheus)** | 6417 | Alternative cluster view |

**To import by ID:**
1. Go to **Dashboards → Import**
2. Enter the **Dashboard ID**
3. Click **Load**
4. Select **Prometheus** data source
5. Click **Import**

---

## 📈 Dashboard Features:

- ✅ **Auto-refresh every 10 seconds**
- ✅ **Last 1 hour of data** (adjustable)
- ✅ **Real-time metrics**
- ✅ **Color-coded alerts**
- ✅ **Interactive graphs** (zoom, pan)
- ✅ **Export to PNG/PDF**

---

## 🎨 Customize Dashboard:

### Add More Panels:
1. Click **"Add panel"** (top right)
2. Select **"Add a new panel"**
3. Enter PromQL query (examples below)
4. Choose visualization type
5. Click **"Apply"**

### Example Queries:

**Frontend Request Rate:**
```promql
rate(http_requests_total{namespace="production",service="frontend"}[5m])
```

**Backend Error Rate:**
```promql
rate(http_requests_total{namespace="production",service="backend",status=~"5.."}[5m])
```

**MySQL Connections:**
```promql
mysql_global_status_threads_connected{namespace="production"}
```

**Pod Availability (%):**
```promql
100 * (kube_deployment_status_replicas_available{namespace="production"} / kube_deployment_spec_replicas{namespace="production"})
```

---

## 🔥 Quick Access Commands:

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access Prometheus (raw metrics)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-stack-prometheus 9090:9090

# Check if metrics are being collected
kubectl get servicemonitors -n production

# View Prometheus targets
# Open: http://localhost:9090/targets (after port-forward)
```

---

## 📱 Mobile Access:

Grafana dashboards are mobile-responsive!
- Access from phone/tablet using same URL
- Swipe to navigate panels
- Pinch to zoom graphs

---

## 💾 Save & Share:

### Export Dashboard:
1. Open dashboard
2. Click **⚙️ (Settings)** → **JSON Model**
3. Copy JSON
4. Save to file

### Share Dashboard:
1. Click **🔗 (Share)** → **Link**
2. Set time range
3. Copy link
4. Share with team

---

## 🎯 Pro Tips:

1. **Set up TV Display:** Use kiosk mode
   ```
   http://localhost:3000/d/dashboard-id?kiosk
   ```

2. **Create Playlists:** Rotate between dashboards
   - Go to **Dashboards → Playlists**
   - Add dashboards
   - Set rotation interval

3. **Set Alerts:** Click panel → Edit → Alert
   - Set threshold
   - Configure notification channel

4. **Use Variables:** Make dashboard dynamic
   - Settings → Variables
   - Add `$namespace`, `$pod` variables
   - Use in queries: `{namespace="$namespace"}`

---

**Your real-time production dashboard is ready! 🚀**
