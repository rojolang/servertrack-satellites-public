# 🛰️ ServerTrack Satellites - Turn-Key Landing Page Deployment

**The ultimate turn-key solution for automated campaign deployment with Voluum integration.**

## ⚡ Quick Start - One Command Installation

Install and run ServerTrack Satellites on any Ubuntu server:

```bash
curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites/main/install.sh | bash
```

## 🎯 What This Does

ServerTrack Satellites is a **production-ready API service** that:

- ✅ **Deploys landing pages instantly** with Voluum tracking integration
- ✅ **Handles nginx configuration** automatically with SSL certificates  
- ✅ **Manages campaign parameters** with stealth Facebook ad compliance
- ✅ **Processes concurrent deployments** with worker pool architecture
- ✅ **Provides comprehensive logging** with structured JSON output
- ✅ **Includes security hardening** with proper headers and validation

## 🔧 API Endpoints

### POST /api/v1/lander
Deploy a new landing page campaign:

```bash
curl -X POST http://localhost:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "your-campaign-id",
    "landing_page_id": "your-landing-page-id",
    "subdomain": "test"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "🛰️ Satellite deployed successfully! Your beautiful lander is live and tracking.",
  "subdomain": "test.puritysalt.com",
  "url": "https://test.puritysalt.com",
  "request_id": "uuid-here",
  "duration": "2.1s",
  "timestamp": "2025-08-06T02:30:45Z"
}
```

### GET /api/v1/landers
List all deployed campaigns:

```bash
curl http://localhost:8080/api/v1/landers
```

### GET /health
System health check:

```bash
curl http://localhost:8080/health
```

### GET /metrics
System performance metrics:

```bash
curl http://localhost:8080/metrics
```

## 🛠️ Configuration

Configure via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Server host |
| `BASE_DOMAIN` | `puritysalt.com` | Base domain for subdomains |
| `LOG_LEVEL` | `info` | Logging level (debug, info, warn, error) |
| `WORKER_POOL_SIZE` | `4` | Number of deployment workers |
| `DEPLOYMENT_QUEUE_SIZE` | `100` | Max queued deployments |

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

### Manual Installation
```bash
# Clone repository
git clone https://github.com/rojolang/servertrack-satellites.git
cd servertrack-satellites

# Run installer
chmod +x install.sh
./install.sh

# Or build manually
go build -o servertrack-satellites .
./servertrack-satellites
```

## 🔍 Monitoring

### Structured Logging
All requests are logged with full context:
```json
{
  "@timestamp": "2025-08-06T02:30:45.123Z",
  "level": "info", 
  "message": "🔄 Satellite request received",
  "request_id": "uuid-here",
  "method": "POST",
  "path": "/api/v1/lander",
  "remote_addr": "192.168.1.100"
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
curl -X POST http://localhost:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "camp-123",
    "landing_page_id": "lp-456", 
    "subdomain": "demo"
  }'

# Result: https://demo.puritysalt.com deployed with tracking
```

### List All Deployments
```bash
curl http://localhost:8080/api/v1/landers | jq
```

### Check System Health
```bash
curl http://localhost:8080/health | jq
```

## 🎯 Features

### ✅ Turn-Key Operation
- **One-line installation** on Ubuntu servers
- **Automatic dependency management** 
- **Zero configuration required**
- **Production-ready defaults**

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

- **Ubuntu 24.04 LTS** (recommended)
- **Go 1.21+** (auto-installed)
- **nginx** (auto-configured)
- **SSL certificates** (auto-generated with Certbot)

## 🤝 Support

- **GitHub Issues**: Report bugs and request features
- **Documentation**: Complete API documentation included
- **Monitoring**: Built-in health checks and metrics
- **Logging**: Comprehensive structured logging

---

**🛰️ Built for production by the ServerTrack Team**

*Turn-key solution - just run the installer and start deploying beautiful campaigns!*