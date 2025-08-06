# 🛰️ ServerTrack Satellites - Public Binary Distribution

**Turn-key landing page deployment system with Voluum tracking integration.**

## ⚡ Quick Installation

**One-line installation on Ubuntu servers:**

```bash
curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites-public/main/public-install.sh | sudo bash
```

## 📦 Manual Installation

```bash
# Download binary from releases
curl -fsSL https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites -o servertrack-satellites
chmod +x servertrack-satellites

# Run directly
sudo ./servertrack-satellites
```

## 🚀 What It Does

ServerTrack Satellites automatically:

- ✅ **Sets up production API server** on port 8080
- ✅ **Installs all dependencies** (nginx, certbot, etc.)  
- ✅ **Configures SSL certificates** with auto-renewal
- ✅ **Provides campaign deployment API** with Voluum integration
- ✅ **Facebook ad compliance** (stealth tracking)
- ✅ **Production monitoring** and verbose logging

## 📋 Requirements

- **OS:** Ubuntu 22.04 or 24.04 LTS
- **Access:** Root/sudo privileges
- **Ports:** 80, 443, 8080 available
- **Network:** Internet connection for dependencies

## 🧪 Live Demo Server

**Test the system live:**

- **Server:** http://192.241.148.17:8080
- **Health:** http://192.241.148.17:8080/health  
- **Metrics:** http://192.241.148.17:8080/metrics

## 🎯 API Usage

**Deploy a campaign:**
```bash
curl -X POST http://YOUR-SERVER-IP:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "your-voluum-campaign-id",
    "landing_page_id": "your-voluum-lander-id", 
    "subdomain": "your-domain.com"
  }'
```

**Check system health:**
```bash
curl http://YOUR-SERVER-IP:8080/health
```

**View active deployments:**
```bash
curl http://YOUR-SERVER-IP:8080/api/v1/landers
```

## ✅ Features

- **Turn-key installation** - Zero manual configuration
- **API-driven deployment** - RESTful endpoints
- **Worker pool architecture** - Concurrent processing  
- **Structured JSON logging** - Request tracking
- **Automatic SSL** - Certbot integration
- **Voluum tracking** - Stealth parameter injection
- **Production ready** - systemd service with auto-restart

## 📊 Technical Details

- **Binary size:** 5.3MB (statically linked Go)
- **Memory usage:** ~11MB RAM
- **Installation time:** ~45 seconds
- **Deployment time:** ~6 seconds per campaign
- **Concurrent capacity:** 4 simultaneous deployments

---

**🛰️ Ready for production deployment!**

*This is the public binary distribution. Source code is maintained in a private repository.*