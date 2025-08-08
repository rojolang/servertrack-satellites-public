# 🛰️ ServerTrack Satellites

**Enterprise-grade landing page deployment platform with automatic SSL, nginx configuration, and campaign tracking integration.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2022.04%2F24.04-orange.svg)](https://ubuntu.com)

## 🚀 Quick Start

Deploy ServerTrack Satellites on any Ubuntu server with a single command:

```bash
curl -fsSL https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites | sudo bash
```

**That's it!** The binary is completely self-contained and automatically handles:

- ✅ **Dependency Installation** - nginx, certbot, SSL tools
- ✅ **Service Configuration** - systemd with security hardening  
- ✅ **Template Creation** - Beautiful landing page templates
- ✅ **Infrastructure Setup** - Directory structure, permissions
- ✅ **SSL Automation** - Let's Encrypt certificate provisioning
- ✅ **Health Monitoring** - Built-in status and metrics endpoints

## 🎯 What ServerTrack Satellites Does

ServerTrack Satellites is a **production-ready API service** that automates landing page deployment for marketing campaigns:

### Core Features

- **🚀 Instant Deployments** - Deploy landing pages in seconds via REST API
- **🔒 Automatic SSL** - Let's Encrypt certificates with auto-renewal
- **⚙️ nginx Integration** - Automatic web server configuration and optimization
- **📊 Campaign Tracking** - Built-in Voluum integration and analytics
- **🎯 Path-Based Routing** - Deploy to `/1/`, `/2/`, `/3/` with auto-increment
- **📦 Multi-Source Support** - GitHub repositories, ZIP files, or templates
- **🛡️ Security Hardened** - Rate limiting, security headers, input validation
- **📈 Production Ready** - Structured logging, metrics, health checks

### Advanced Capabilities

- **Dynamic Domain Support** - Any domain, not just subdomains
- **Concurrent Processing** - Worker pool architecture for high throughput
- **Graceful Shutdown** - Zero-downtime deployments and updates  
- **Self-Installing** - No external dependencies or complex setup
- **Enterprise Security** - systemd sandboxing, minimal permissions
- **Comprehensive Monitoring** - JSON logs, Prometheus-compatible metrics

## 📡 API Endpoints

Once installed, ServerTrack Satellites exposes a REST API on port 8080:

### Core Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check and system status |
| `/metrics` | GET | System performance metrics |
| `/api/v1/landers` | GET | List all deployed campaigns |
| `/api/v1/lander` | POST | Deploy new landing page |
| `/api/v1/provision` | POST | Advanced deployment with custom domains |

### Deployment Examples

#### Basic Campaign Deployment
```bash
curl -X POST http://your-server:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "campaign-123",
    "landing_page_id": "lp-456",
    "subdomain": "demo.yourdomain.com"
  }'
```

#### Path-Based Deployment
```bash
curl -X POST http://your-server:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "fb-campaign-789",
    "landing_page_id": "lp-social-001", 
    "subdomain": "fb.yourdomain.com/1/"
  }'
```

#### GitHub Repository Deployment
```bash
curl -X POST http://your-server:8080/api/v1/provision \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "custom.yourdomain.com",
    "github_repo": "https://github.com/youruser/landing-page"
  }'
```

#### ZIP File Deployment
```bash
curl -X POST http://your-server:8080/api/v1/provision \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "promo.yourdomain.com", 
    "zip_file_url": "https://example.com/landing-page.zip"
  }'
```

## 🛠️ Alternative Installation Methods

### Manual Installation
```bash
# Download binary
curl -fsSL https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites -o servertrack-satellites

# Make executable and install
chmod +x servertrack-satellites
sudo ./servertrack-satellites --install
```

### Verify Installation
```bash
# Check service status
sudo systemctl status servertrack-satellites

# View logs
sudo journalctl -u servertrack-satellites -f

# Test API
curl http://localhost:8080/health
```

## 📋 System Requirements

- **Operating System**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **Architecture**: x86_64 (amd64)
- **RAM**: Minimum 1GB, Recommended 2GB+
- **Storage**: Minimum 2GB available space
- **Network**: Internet access for package installation and SSL certificates
- **Privileges**: Root access required for installation only

## 🔧 Configuration

ServerTrack Satellites is configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | API server port |
| `HOST` | `0.0.0.0` | Server bind address |
| `BASE_DOMAIN` | `puritysalt.com` | Default domain for subdomains |
| `LOG_LEVEL` | `info` | Logging level (debug/info/warn/error) |
| `WORKER_POOL_SIZE` | `4` | Deployment worker threads |
| `DEPLOYMENT_QUEUE_SIZE` | `100` | Max queued deployments |
| `MAX_REQUEST_SIZE` | `1048576` | Max request size in bytes |

### Environment Configuration

Create `/etc/systemd/system/servertrack-satellites.service.d/override.conf`:

```ini
[Service]
Environment="BASE_DOMAIN=yourdomain.com"
Environment="LOG_LEVEL=debug"
Environment="WORKER_POOL_SIZE=8"
```

Then reload: `sudo systemctl daemon-reload && sudo systemctl restart servertrack-satellites`

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client Apps   │───▶│  ServerTrack API │───▶│  nginx + SSL    │
│                 │    │   (Port 8080)    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                               │                          │
                               ▼                          ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Worker Pool     │    │  Landing Pages  │
                       │  (Deployments)   │    │  (/var/www/)    │
                       └──────────────────┘    └─────────────────┘
```

### Component Breakdown

- **API Layer**: Go HTTP server with Gorilla Mux routing
- **Worker Pool**: Concurrent deployment processing
- **nginx Integration**: Automatic configuration and SSL management
- **File System**: Template-based landing page generation
- **Security Layer**: Request validation, rate limiting, sandboxing
- **Monitoring**: Structured JSON logging and metrics

## 📊 Monitoring & Observability

### Health Monitoring
```bash
curl http://localhost:8080/health | jq
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-08-08T18:30:45Z",
  "uptime": "2h15m30s",
  "version": "2.0.3",
  "active_deployments": 3,
  "total_requests": 1547
}
```

### Performance Metrics
```bash
curl http://localhost:8080/metrics | jq
```

### Log Analysis
```bash
# Real-time logs with JSON formatting
sudo journalctl -u servertrack-satellites -f -o json-pretty

# Filter by log level
sudo journalctl -u servertrack-satellites | grep '"level":"error"'

# Deployment-specific logs
sudo journalctl -u servertrack-satellites | grep '"deployment"'
```

## 🚦 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status and logs
sudo systemctl status servertrack-satellites
sudo journalctl -u servertrack-satellites -n 50

# Verify binary permissions
ls -la /opt/servertrack-satellites/servertrack-satellites
```

#### SSL Certificate Issues
```bash
# Check certbot status
sudo certbot certificates

# Test SSL manually
sudo certbot --nginx -d yourdomain.com --dry-run

# Check nginx configuration
sudo nginx -t
```

#### Port Already in Use
```bash
# Find what's using port 8080
sudo lsof -i :8080

# Kill conflicting processes
sudo pkill -f servertrack-satellites
```

#### Permission Errors
```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/
sudo chown -R root:root /opt/servertrack-satellites/

# Verify systemd service file
sudo systemctl cat servertrack-satellites
```

### Performance Tuning

#### High-Traffic Configuration
```bash
# Increase worker pool size
sudo systemctl edit servertrack-satellites
```

Add:
```ini
[Service]
Environment="WORKER_POOL_SIZE=16"
Environment="DEPLOYMENT_QUEUE_SIZE=500"
```

#### Resource Monitoring
```bash
# Check system resources
htop
df -h
free -h

# Monitor API performance
curl -w "@curl-format.txt" http://localhost:8080/health
```

## 🔒 Security Considerations

ServerTrack Satellites implements multiple security layers:

- **Input Validation**: All API inputs are validated and sanitized
- **Request Size Limiting**: Prevents DoS attacks via large payloads
- **Security Headers**: CSRF, XSS, and clickjacking protection
- **systemd Sandboxing**: Restricted file system access and privileges
- **SSL/TLS**: Automatic HTTPS with strong cipher suites
- **Rate Limiting**: Built-in protection against abuse
- **Structured Logging**: Complete audit trail of all operations

## 📈 Performance & Scalability

### Benchmarks

- **Concurrent Deployments**: Up to 50 simultaneous deployments
- **API Throughput**: 1000+ requests/second
- **Memory Usage**: ~50MB base, +10MB per active deployment
- **Startup Time**: <2 seconds cold start
- **SSL Certificate**: <30 seconds for new domains

### Scaling Recommendations

- **Single Server**: Handle up to 10,000 deployed pages
- **Load Balancing**: Deploy multiple instances behind nginx
- **Database**: Consider external storage for >100,000 deployments
- **CDN Integration**: CloudFlare or AWS CloudFront for global reach

## 🤝 Contributing

This is a production system. For bug reports or feature requests, please:

1. Check existing issues first
2. Provide detailed reproduction steps
3. Include system information (Ubuntu version, resources)
4. Test with the latest binary release

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

Built with ❤️ using:
- **Go** - Fast, reliable backend services
- **nginx** - High-performance web server
- **Let's Encrypt** - Free SSL certificates for everyone
- **Ubuntu** - Stable, secure operating system

---

**🛰️ ServerTrack Satellites** - *Deploying beautiful campaigns at light speed*