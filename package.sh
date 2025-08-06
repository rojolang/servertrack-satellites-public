#!/bin/bash

# 🛰️ ServerTrack Satellites - Package Builder
# Creates a single deployable package with everything needed

set -e

echo "🛰️ ServerTrack Satellites - Building deployment package..."

# Build the binary
echo "🔧 Building ServerTrack Satellites binary..."
export PATH=$PATH:/usr/local/go/bin
go build -ldflags="-s -w" -o servertrack-satellites .

# Create deployment directory
DEPLOY_DIR="servertrack-satellites-deploy"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

echo "📦 Packaging deployment files..."

# Copy all necessary files
cp servertrack-satellites "$DEPLOY_DIR/"
cp auto-setup.sh "$DEPLOY_DIR/"
cp deploy-all.sh "$DEPLOY_DIR/"
cp README.md "$DEPLOY_DIR/"

# Create the ultimate one-command installer
cat > "$DEPLOY_DIR/install.sh" << 'EOF'
#!/bin/bash

# 🛰️ ServerTrack Satellites - One-Command Installer
# Run this script on any Ubuntu 22/24 server to install everything automatically

set -e

echo "🛰️ ServerTrack Satellites - One-Command Installer"
echo "This will install and configure everything needed..."

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if we have the necessary files
if [ ! -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    echo "💥 servertrack-satellites binary not found!"
    echo "Make sure you have all files in the same directory:"
    echo "- servertrack-satellites (binary)"
    echo "- auto-setup.sh"
    echo "- install.sh (this script)"
    exit 1
fi

# Run the deployment
echo "🚀 Starting full deployment..."
bash "$SCRIPT_DIR/deploy-all.sh"

echo "✅ Installation complete!"
EOF

chmod +x "$DEPLOY_DIR/install.sh"

# Create a simple info file
cat > "$DEPLOY_DIR/DEPLOYMENT.md" << 'EOF'
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
EOF

# Create a tarball for easy distribution
echo "📦 Creating distribution tarball..."
tar czf servertrack-satellites-deploy.tar.gz "$DEPLOY_DIR"

echo ""
echo "🎉 Deployment package created successfully!"
echo ""
echo "📁 Files created:"
echo "   📂 $DEPLOY_DIR/ - Deployment directory"
echo "   📦 servertrack-satellites-deploy.tar.gz - Distribution package"
echo ""
echo "🚀 To deploy on a Ubuntu server:"
echo "   1. Copy the deployment directory to your server"
echo "   2. Run: sudo bash install.sh"
echo "   3. Done! API will be running on port 8080"
echo ""
echo "📦 Or distribute the tarball:"
echo "   tar xzf servertrack-satellites-deploy.tar.gz"
echo "   cd servertrack-satellites-deploy"
echo "   sudo bash install.sh"
echo ""
echo "✨ Everything is packaged and ready for deployment!"