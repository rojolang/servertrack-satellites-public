#!/bin/bash

# 🛰️ ServerTrack Satellites - Ultimate Auto-Setup Script
# This script auto-installs and configures EVERYTHING needed on Ubuntu 22/24

set -e

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}✅ $1${NC}"; }
step() { echo -e "${BLUE}🔹 $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}💥 $1${NC}"; exit 1; }

# ASCII Banner
echo -e "${PURPLE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║                🛰️ ServerTrack Satellites 🛰️                ║"
echo "  ║            Ultimate Turn-Key Auto Setup                      ║"
echo "  ║                                                              ║"
echo "  ║   🚀 Installs EVERYTHING automatically on Ubuntu 22/24 🚀   ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

step "Detecting system..."
if [[ $EUID -eq 0 ]]; then
   warn "Running as root - this is fine for server setup"
fi

# Detect Ubuntu version
if ! grep -q "Ubuntu" /etc/os-release; then
    error "This script requires Ubuntu 22.04 or 24.04"
fi

UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
log "Ubuntu ${UBUNTU_VERSION} detected - perfect!"

step "Updating package repositories..."
apt update -qq >/dev/null 2>&1

step "Installing ALL required packages..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    curl wget git unzip \
    nginx certbot python3-certbot-nginx \
    jq htop net-tools \
    build-essential \
    supervisor \
    >/dev/null 2>&1

log "All packages installed successfully!"

step "Installing Go 1.21.5..."
if ! command -v go &> /dev/null; then
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
    log "Go installed successfully!"
else
    log "Go already installed: $(go version)"
fi

step "Creating directories and templates..."
mkdir -p /root/templates
mkdir -p /var/www
mkdir -p /opt/servertrack-satellites
mkdir -p /var/log/servertrack-satellites

# Create the nginx template directory and files
step "Setting up nginx configuration templates..."
mkdir -p /var/www/template

# Create a simple landing page template
cat > /var/www/template/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Campaign Landing Page</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f0f0f0; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        .btn { background: #007cba; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px; }
        .btn:hover { background: #005a87; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛰️ Campaign Landing Page</h1>
        <p>Your beautiful landing page is now live and tracking!</p>
        <a href="/click/1" class="btn">Click Here - Option 1</a>
        <a href="/click/2" class="btn">Click Here - Option 2</a>
        <a href="/click/3" class="btn">Click Here - Option 3</a>
    </div>

    <!-- Voluum tracking script will be injected here -->
    <script>
        console.log('🛰️ ServerTrack Satellites - Landing page loaded');
        console.log('Campaign tracking active:', window.location.search);
    </script>
</body>
</html>
EOF

# Create the ultimate deployment script
cat > /root/templates/quick-deploy.sh << 'EOF'
#!/bin/bash
# Ultimate deployment script for ServerTrack Satellites

set -e

SUBDOMAIN="$1"
CAMPAIGN_ID="$2"
LANDING_PAGE_ID="$3"

if [ $# -ne 3 ]; then
    echo "Usage: $0 <subdomain> <campaign_id> <landing_page_id>"
    exit 1
fi

echo "🛰️ Deploying satellite: $SUBDOMAIN"

# Create site directory
mkdir -p "/var/www/$SUBDOMAIN"
cp -r /var/www/template/* "/var/www/$SUBDOMAIN/"

# Create nginx config with tracking
cat > "/etc/nginx/sites-available/$SUBDOMAIN" << NGINXEOF
server {
    server_name $SUBDOMAIN;
    root /var/www/$SUBDOMAIN;
    index index.html;

    # Handle click tracking - forward to Voluum
    location /click/ {
        proxy_pass http://track.puritysalt.com;
        proxy_set_header Host track.puritysalt.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        # Campaign configuration
        set \$campaign_id "$CAMPAIGN_ID";
        set \$lander_id "$LANDING_PAGE_ID";
        
        # Inject tracking parameters
        set \$final_args "cpid=\$campaign_id&lpid=\$lander_id";
        if (\$args != "") {
            set \$final_args "\$final_args&\$args";
        }
        
        try_files \$uri \$uri/ /index.html;
        
        # Inject parameters for Voluum tracking
        sub_filter_once off;
        sub_filter '</head>' '<script>if(!window.location.search.includes("cpid")){history.replaceState(null,"","?\$final_args");}</script></head>';
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    listen 80;
}
NGINXEOF

# Enable site
ln -sf "/etc/nginx/sites-available/$SUBDOMAIN" "/etc/nginx/sites-enabled/$SUBDOMAIN"

# Test nginx config
nginx -t && systemctl reload nginx

# Try to get SSL certificate (non-blocking)
certbot --nginx -d "$SUBDOMAIN" --non-interactive --agree-tos --email admin@puritysalt.com >/dev/null 2>&1 || echo "SSL setup skipped - domain may not be ready"

# Set permissions
chown -R www-data:www-data "/var/www/$SUBDOMAIN"

echo "✅ Satellite deployed: https://$SUBDOMAIN"
EOF

chmod +x /root/templates/quick-deploy.sh

log "Templates and deployment script created!"

step "Creating ServerTrack Satellites service..."

# Create systemd service file
cat > /etc/systemd/system/servertrack-satellites.service << 'EOF'
[Unit]
Description=ServerTrack Satellites - Landing Page Deployment API
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/servertrack-satellites
ExecStart=/opt/servertrack-satellites/servertrack-satellites
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=servertrack-satellites

# Environment variables
Environment=PORT=8080
Environment=HOST=0.0.0.0
Environment=LOG_LEVEL=info
Environment=BASE_DOMAIN=puritysalt.com

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/opt/servertrack-satellites /var/www /etc/nginx /var/log
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

log "Systemd service created!"

step "Starting nginx and enabling services..."
systemctl enable nginx
systemctl start nginx
systemctl enable servertrack-satellites

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default

# Create a simple nginx default config
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        return 200 '🛰️ ServerTrack Satellites Server Ready!\n\nAPI available at: http://your-server-ip:8080\n\nDeploy a campaign:\ncurl -X POST http://your-server-ip:8080/api/v1/lander -H "Content-Type: application/json" -d '\''{"campaign_id":"test","landing_page_id":"test","subdomain":"demo.yourdomain.com"}'\''';
        add_header Content-Type text/plain;
    }
}
EOF

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
systemctl reload nginx

log "nginx configured and started!"

step "Setting up firewall (if ufw is available)..."
if command -v ufw >/dev/null 2>&1; then
    ufw --force enable >/dev/null 2>&1 || true
    ufw allow 22/tcp >/dev/null 2>&1 || true
    ufw allow 80/tcp >/dev/null 2>&1 || true
    ufw allow 443/tcp >/dev/null 2>&1 || true
    ufw allow 8080/tcp >/dev/null 2>&1 || true
    log "Firewall configured!"
else
    warn "UFW not available, firewall not configured"
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}${BOLD}🎉 AUTO-SETUP COMPLETE! 🎉${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}🛰️ ServerTrack Satellites is ready!${NC}"
echo ""
echo -e "${BOLD}📡 Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "${BOLD}🌐 Test page: ${GREEN}http://$SERVER_IP${NC}"
echo -e "${BOLD}🔧 API will be at: ${GREEN}http://$SERVER_IP:8080${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "1. Copy your ServerTrack Satellites binary to: ${YELLOW}/opt/servertrack-satellites/${NC}"
echo -e "2. Start the service: ${YELLOW}systemctl start servertrack-satellites${NC}"
echo -e "3. Check status: ${YELLOW}systemctl status servertrack-satellites${NC}"
echo ""
echo -e "${BOLD}🚀 Deploy a campaign:${NC}"
echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
echo -e "${CYAN}  -d '{\"campaign_id\":\"test\",\"landing_page_id\":\"test\",\"subdomain\":\"demo.yourdomain.com\"}'${NC}"
echo ""
echo -e "${PURPLE}✨ Everything is configured and ready to go! ✨${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EOF

chmod +x /root/rojolang-api/auto-setup.sh

log "Auto-setup script created!"