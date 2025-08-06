# 🛰️ ServerTrack Satellites - Deployment Package

## Quick Start

**One-command installation on Ubuntu 22/24:**

```bash
sudo bash install.sh
```

This will:
- ✅ Install all dependencies (Go, nginx, certbot, etc.)
- ✅ Configure nginx with templates
- ✅ Set up systemd service
- ✅ Start ServerTrack Satellites API
- ✅ Configure firewall
- ✅ Set up deployment templates

## Files Included

- `servertrack-satellites` - Main API binary
- `install.sh` - One-command installer
- `auto-setup.sh` - System setup script  
- `deploy-all.sh` - Full deployment script
- `README.md` - Complete documentation

## After Installation

The API will be available at:
- **API**: http://your-server-ip:8080
- **Health**: http://your-server-ip:8080/health
- **Metrics**: http://your-server-ip:8080/metrics

Deploy a campaign:
```bash
curl -X POST http://your-server-ip:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "test-123",
    "landing_page_id": "lp-456", 
    "subdomain": "demo.yourdomain.com"
  }'
```

## Management

```bash
# Service management
sudo systemctl status servertrack-satellites
sudo systemctl restart servertrack-satellites
sudo systemctl stop servertrack-satellites

# View logs
sudo journalctl -u servertrack-satellites -f

# Check API health
curl http://localhost:8080/health
```

## Requirements

- Ubuntu 22.04 or 24.04 LTS
- Root access (for system configuration)
- Internet connection (for dependencies)

---

**🛰️ Ready to deploy beautiful campaigns!**
