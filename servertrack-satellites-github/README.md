# 🛰️ ServerTrack Satellites - Slim Landing Page Deployment

**Turn-key satellite server deployment with Voluum tracking integration.**

## ⚡ One-Command Installation

Install on any Ubuntu server:

```bash
sudo bash install.sh
```

## 🎯 What This Does

ServerTrack Satellites is a **production-ready API service** that:

- ✅ **Deploys landing pages instantly** with Voluum tracking integration
- ✅ **Handles nginx configuration** automatically with SSL certificates  
- ✅ **Manages campaign parameters** with stealth Facebook ad compliance
- ✅ **Processes concurrent deployments** with worker pool architecture
- ✅ **Provides comprehensive logging** with structured JSON output
- ✅ **Includes security hardening** with proper headers and validation

## 📦 Package Contents

**Slim deployment package (5.3MB):**
- `install.sh` - One-command installer (414 bytes)
- `auto-setup.sh` - System setup script (8.4KB)
- `deploy-all.sh` - Deployment orchestrator (2.7KB) 
- `servertrack-satellites` - Production API binary (5.4MB)

## 🔧 API Endpoints

### POST /api/v1/lander
Deploy a new landing page campaign:

#### Basic Domain Deployment
```bash
curl -X POST http://YOUR-SERVER-IP:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "your-campaign-id",
    "landing_page_id": "your-landing-page-id",
    "subdomain": "test.puritysalt.com"
  }'
```

#### 🚀 Path-Based Deployment (NEW!)
Deploy to specific paths with automatic folder duplication and campaign parameter injection:

```bash
# Deploy to specific path
curl -X POST http://YOUR-SERVER-IP:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "campaign-123",
    "landing_page_id": "landing-456",
    "subdomain": "fb.puritysalt.com/1/"
  }'

# Auto-increment path (finds next available /1, /2, /3, etc.)
curl -X POST http://YOUR-SERVER-IP:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "campaign-456",
    "landing_page_id": "landing-789", 
    "subdomain": "fb.puritysalt.com/"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "🛰️ Satellite deployment initiated!",
  "subdomain": "test.puritysalt.com",
  "url": "https://test.puritysalt.com",
  "request_id": "uuid-here",
  "duration": "140.532µs"
}
```

### GET /api/v1/landers
List all deployed campaigns:

```bash
curl http://YOUR-SERVER-IP:8080/api/v1/landers
```

### GET /health
System health check:

```bash
curl http://YOUR-SERVER-IP:8080/health
```

### GET /metrics
System performance metrics:

```bash
curl http://YOUR-SERVER-IP:8080/metrics
```

## 🛠️ Configuration

Configure via environment variables in systemd service:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `BASE_DOMAIN` | `puritysalt.com` | Base domain for subdomains |
| `LOG_LEVEL` | `info` | Logging level (debug, info, warn, error) |

## 🏗️ Architecture

### Turn-Key Design
- **Zero configuration needed** - works out of the box
- **Environment-based config** - easy to customize
- **Automatic dependency handling** - installs everything needed
- **Production-ready defaults** - optimized for performance

### Security Features
- **Request size limiting** - prevents DoS attacks
- **Comprehensive security headers** - protects against common attacks
- **Input validation** - sanitizes all user input
- **Structured logging** - full audit trail
- **Graceful error handling** - prevents crashes

### Performance Features  
- **Concurrent processing** - handles multiple deployments simultaneously
- **Worker pool architecture** - optimal resource utilization
- **Buffered deployment queue** - handles traffic spikes
- **Graceful shutdown** - proper cleanup on stop

## 📦 Production Deployment

### Systemd Service
The installer automatically sets up a systemd service:

```bash
# Service management
sudo systemctl start servertrack-satellites
sudo systemctl stop servertrack-satellites
sudo systemctl restart servertrack-satellites
sudo systemctl status servertrack-satellites

# View logs
sudo journalctl -u servertrack-satellites -f
```

## 🔍 Monitoring

### Structured Logging
All requests are logged with full context:
```json
{
  "@timestamp": "2025-08-06T03:13:08Z",
  "level": "info", 
  "message": "🔄 Satellite request received",
  "request_id": "uuid-here",
  "method": "POST",
  "path": "/api/v1/lander"
}
```

### Health Monitoring
Monitor service health at `/health` endpoint with comprehensive system status.

### Performance Metrics
Track system performance at `/metrics` endpoint with:
- Total requests processed
- Active deployments
- System uptime
- Success rates

## 🚀 Examples

### Basic Deployment
```bash
# Deploy a campaign
curl -X POST http://192.241.148.17:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "camp-123",
    "landing_page_id": "lp-456", 
    "subdomain": "demo.puritysalt.com"
  }'

# Result: https://demo.puritysalt.com deployed with tracking
```

### List All Deployments
```bash
curl http://192.241.148.17:8080/api/v1/landers | jq
```

### Check System Health
```bash
curl http://192.241.148.17:8080/health | jq
```

## 🎯 Features

### ✅ Turn-Key Operation
- **One-line installation** on Ubuntu servers
- **Automatic dependency management** 
- **Zero configuration required**
- **Production-ready defaults**

### 🚀 Path-Based Deployments (NEW!)
- **Automatic folder duplication** with /1, /2, /3 incremental paths
- **Campaign parameter injection** into HTML for tracking
- **nginx path routing** automatically configured
- **Smart path detection** - finds next available number automatically

### ✅ Security Hardened
- **Request validation and sanitization**
- **Security headers (XSS, CSRF, etc.)**
- **Request size limiting**  
- **Structured audit logging**

### ✅ High Performance
- **Concurrent deployment processing**
- **Optimized worker pool** 
- **Efficient resource usage**
- **Graceful shutdown handling**

### ✅ Facebook Ad Compliant
- **Stealth parameter injection**
- **Clean URL structure**
- **No visible redirects**
- **UTM parameter preservation**

## 📋 Requirements

- **Ubuntu 22.04 or 24.04 LTS**
- **Root access** (for system configuration)
- **Internet connection** (for dependencies)

## 🔧 Troubleshooting

### Common Issues

**Port 8080 already in use:**
```bash
sudo lsof -i :8080
sudo pkill -f servertrack-satellites
sudo systemctl restart servertrack-satellites
```

**nginx config errors:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

**Service won't start:**
```bash
sudo journalctl -u servertrack-satellites -n 20
```

## 💡 Pro Tips

1. **Always check health endpoint first:** `curl http://YOUR-IP:8080/health`
2. **Monitor logs in real-time:** `sudo journalctl -u servertrack-satellites -f`
3. **Use jq for pretty JSON:** `curl http://YOUR-IP:8080/metrics | jq`
4. **Test with simple deployment first** before complex campaigns

---

**🛰️ Built for production deployment**

*Turn-key solution - just run the installer and start deploying beautiful campaigns!*