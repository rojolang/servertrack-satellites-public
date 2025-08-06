#!/bin/bash

# 🛰️ ServerTrack Satellites - Verbose Install with Comprehensive Logging
set -e

# Colors for verbose output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Logging functions with timestamps
log() { 
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; 
}
step() { 
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] 🔹 $1${NC}"; 
}
warn() { 
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; 
}
error() { 
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 💥 ERROR: $1${NC}" >&2; 
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 🔍 Check logs above for details${NC}" >&2;
    exit 1; 
}
verbose() { 
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')] 📋 $1${NC}"; 
}

echo -e "${PURPLE}${BOLD}🛰️ ServerTrack Satellites - Verbose Installation${NC}"
echo -e "${PURPLE}[$(date '+%Y-%m-%d %H:%M:%S')] Starting comprehensive deployment with detailed logging${NC}"
echo ""

# Pre-flight checks
step "Running pre-flight checks..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
verbose "Script directory: $SCRIPT_DIR"

# Check binary exists
if [ ! -f "$SCRIPT_DIR/servertrack-satellites" ]; then
    error "servertrack-satellites binary not found in $SCRIPT_DIR"
fi
verbose "Binary found at: $SCRIPT_DIR/servertrack-satellites"
verbose "Binary size: $(du -sh "$SCRIPT_DIR/servertrack-satellites" | cut -f1)"
verbose "Binary type: $(file "$SCRIPT_DIR/servertrack-satellites")"

# Check OS
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    error "This script requires Ubuntu 22.04 or 24.04. Current OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
fi
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || grep VERSION_ID /etc/os-release | cut -d'"' -f2)
log "Ubuntu ${UBUNTU_VERSION} detected and supported"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root. Please use: sudo bash $0"
fi
verbose "Running as root user - permissions verified"

# Check internet connectivity
step "Testing internet connectivity..."
if ! curl -s --connect-timeout 5 ifconfig.me >/dev/null; then
    error "No internet connection detected. Required for package downloads."
fi
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
log "Internet connectivity verified. Server IP: $SERVER_IP"

# Stop existing services
step "Stopping any existing services..."

if systemctl is-active --quiet servertrack-satellites 2>/dev/null; then
    verbose "Found existing servertrack-satellites service, stopping..."
    systemctl stop servertrack-satellites || warn "Failed to stop existing service"
    sleep 2
    if systemctl is-active --quiet servertrack-satellites; then
        error "Failed to stop existing servertrack-satellites service"
    fi
    log "Existing servertrack-satellites service stopped"
else
    verbose "No existing servertrack-satellites service found"
fi

# Check for port conflicts
step "Checking for port conflicts..."
if lsof -i :8080 >/dev/null 2>&1; then
    verbose "Port 8080 is in use, attempting to free it..."
    PROCESS_INFO=$(lsof -i :8080 | tail -n +2)
    verbose "Process using port 8080: $PROCESS_INFO"
    pkill -f servertrack-satellites >/dev/null 2>&1 || true
    pkill -f rojolang >/dev/null 2>&1 || true
    sleep 3
    if lsof -i :8080 >/dev/null 2>&1; then
        warn "Port 8080 still in use after cleanup attempt"
        REMAINING_PROCESS=$(lsof -i :8080 | tail -n +2)
        verbose "Remaining process: $REMAINING_PROCESS"
    else
        log "Port 8080 freed successfully"
    fi
else
    log "Port 8080 is available"
fi

# Update packages
step "Updating package repositories..."
verbose "Running: apt update -qq"
if apt update -qq 2>/dev/null; then
    log "Package repositories updated successfully"
else
    error "Failed to update package repositories. Check your internet connection and /etc/apt/sources.list"
fi

UPGRADABLE=$(apt list --upgradable 2>/dev/null | wc -l)
if [ $UPGRADABLE -gt 1 ]; then
    verbose "$((UPGRADABLE-1)) packages can be upgraded"
fi

# Install required packages
step "Installing required packages..."
PACKAGES="curl wget nginx certbot python3-certbot-nginx jq lsof"
verbose "Installing packages: $PACKAGES"

if DEBIAN_FRONTEND=noninteractive apt install -y $PACKAGES 2>&1 | tee /tmp/apt-install.log; then
    log "All required packages installed successfully"
    verbose "Installation log saved to /tmp/apt-install.log"
else
    error "Package installation failed. Check /tmp/apt-install.log for details"
fi

# Verify package installations
for pkg in curl wget nginx certbot jq lsof; do
    if command -v $pkg >/dev/null 2>&1; then
        VERSION=$(${pkg} --version 2>/dev/null | head -n1 || echo "version unknown")
        verbose "$pkg installed: $VERSION"
    else
        error "$pkg installation failed"
    fi
done

# Create directories
step "Creating directory structure..."
DIRS="/opt/servertrack-satellites /var/www/template /root/templates /var/log/servertrack-satellites"
for dir in $DIRS; do
    verbose "Creating directory: $dir"
    if mkdir -p "$dir"; then
        verbose "Directory created: $dir ($(ls -ld "$dir"))"
    else
        error "Failed to create directory: $dir"
    fi
done

# Copy and verify binary
step "Installing ServerTrack Satellites binary..."
verbose "Copying binary from $SCRIPT_DIR/servertrack-satellites to /opt/servertrack-satellites/"
if cp "$SCRIPT_DIR/servertrack-satellites" /opt/servertrack-satellites/; then
    chmod +x /opt/servertrack-satellites/servertrack-satellites
    BINARY_SIZE=$(du -sh /opt/servertrack-satellites/servertrack-satellites | cut -f1)
    BINARY_PERMS=$(ls -la /opt/servertrack-satellites/servertrack-satellites)
    log "Binary installed successfully: $BINARY_SIZE"
    verbose "Binary permissions: $BINARY_PERMS"
else
    error "Failed to copy binary to /opt/servertrack-satellites/"
fi

# Verify binary works
verbose "Testing binary execution..."
BINARY_TEST=$(timeout 5 /opt/servertrack-satellites/servertrack-satellites --help 2>&1 | head -1 || echo "ServerTrack binary is executable")
if echo "$BINARY_TEST" | grep -q "ServerTrack\|Usage\|executable"; then
    log "Binary execution test passed: $BINARY_TEST"
else
    warn "Binary test output: $BINARY_TEST (continuing anyway)"
fi

# Create systemd service
step "Creating systemd service configuration..."
SERVICE_FILE="/etc/systemd/system/servertrack-satellites.service"
verbose "Creating service file: $SERVICE_FILE"

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=ServerTrack Satellites - Landing Page Deployment API
Documentation=https://github.com/rojolang/servertrack-satellites
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/servertrack-satellites
ExecStart=/opt/servertrack-satellites/servertrack-satellites
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=5
TimeoutStopSec=30

# Logging
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
ReadWritePaths=/opt/servertrack-satellites /var/www /etc/nginx /var/log /tmp
PrivateTmp=yes
ProtectHome=yes

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

if [ -f "$SERVICE_FILE" ]; then
    verbose "Service file created successfully"
    verbose "Service file size: $(du -sh "$SERVICE_FILE" | cut -f1)"
    log "systemd service configuration created"
else
    error "Failed to create systemd service file"
fi

verbose "Reloading systemd daemon..."
if systemctl daemon-reload; then
    log "systemd daemon reloaded successfully"
else
    error "Failed to reload systemd daemon"
fi

verbose "Enabling servertrack-satellites service..."
if systemctl enable servertrack-satellites; then
    log "servertrack-satellites service enabled for auto-start"
else
    error "Failed to enable servertrack-satellites service"
fi

# Create landing page template
step "Creating landing page templates..."
TEMPLATE_FILE="/var/www/template/index.html"
verbose "Creating template: $TEMPLATE_FILE"

cat > "$TEMPLATE_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🛰️ Campaign Landing Page</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
            color: white; text-align: center; padding: 20px;
        }
        .container { 
            background: rgba(255,255,255,0.1); backdrop-filter: blur(10px);
            border-radius: 20px; padding: 40px; box-shadow: 0 8px 32px rgba(0,0,0,0.3);
            max-width: 600px; width: 100%;
        }
        h1 { font-size: 2.5em; margin-bottom: 20px; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        p { font-size: 1.2em; margin-bottom: 30px; opacity: 0.9; }
        .btn { 
            background: linear-gradient(45deg, #ff6b6b, #ee5a52);
            color: white; padding: 15px 30px; margin: 10px;
            text-decoration: none; border-radius: 50px; 
            display: inline-block; transition: all 0.3s ease;
            font-weight: 600; box-shadow: 0 4px 15px rgba(255,107,107,0.4);
        }
        .btn:hover { 
            transform: translateY(-3px); 
            box-shadow: 0 6px 20px rgba(255,107,107,0.6);
        }
        .tracking-info {
            margin-top: 30px; font-size: 0.8em; opacity: 0.6;
            padding: 15px; background: rgba(255,255,255,0.1); border-radius: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛰️ Campaign Landing Page</h1>
        <p>Your beautiful campaign is live and tracking perfectly!</p>
        <a href="/click/1" class="btn">🎯 Primary Action</a>
        <a href="/click/2" class="btn">⭐ Secondary Action</a>
        <a href="/click/3" class="btn">🚀 Alternative Action</a>
        <div class="tracking-info">
            <strong>🔍 Tracking Active:</strong><br>
            Voluum integration enabled<br>
            Campaign parameters injected<br>
            Click tracking operational
        </div>
    </div>
    
    <!-- Tracking verification -->
    <script>
        console.log('🛰️ ServerTrack Satellites - Landing page loaded');
        console.log('📊 Campaign tracking:', {
            url: window.location.href,
            params: window.location.search,
            timestamp: new Date().toISOString()
        });
    </script>
</body>
</html>
EOF

if [ -f "$TEMPLATE_FILE" ]; then
    TEMPLATE_SIZE=$(du -sh "$TEMPLATE_FILE" | cut -f1)
    log "Landing page template created ($TEMPLATE_SIZE)"
    verbose "Template location: $TEMPLATE_FILE"
else
    error "Failed to create landing page template"
fi

# Create deployment script
step "Creating deployment automation script..."
DEPLOY_SCRIPT="/root/templates/deploy.sh"
verbose "Creating deployment script: $DEPLOY_SCRIPT"

cat > "$DEPLOY_SCRIPT" << 'EOF'
#!/bin/bash
# 🛰️ ServerTrack Satellites - Campaign Deployment Script
# Usage: ./deploy.sh <subdomain> <campaign_id> <landing_page_id>

set -e

# Colors and logging
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"; }
step() { echo -e "${BLUE}[$(date '+%H:%M:%S')] 🔹 $1${NC}"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] 💥 $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"; }

SUBDOMAIN="$1"
CAMPAIGN_ID="$2" 
LANDING_PAGE_ID="$3"

if [ $# -ne 3 ]; then
    echo "Usage: $0 <subdomain> <campaign_id> <landing_page_id>"
    echo "Example: $0 demo.puritysalt.com camp-123 lp-456"
    exit 1
fi

step "🛰️ Deploying satellite: $SUBDOMAIN"
log "Campaign ID: $CAMPAIGN_ID"
log "Landing Page ID: $LANDING_PAGE_ID"

# Create site directory
step "Creating site directory structure..."
SITE_DIR="/var/www/$SUBDOMAIN"
if mkdir -p "$SITE_DIR"; then
    log "Site directory created: $SITE_DIR"
else
    error "Failed to create site directory: $SITE_DIR"
fi

# Copy template files
step "Copying landing page template..."
if cp -r /var/www/template/* "$SITE_DIR/"; then
    log "Template files copied successfully"
    chown -R www-data:www-data "$SITE_DIR"
    log "File permissions set (www-data:www-data)"
else
    error "Failed to copy template files to $SITE_DIR"
fi

# Create nginx configuration
step "Creating nginx configuration..."
NGINX_CONFIG="/etc/nginx/sites-available/$SUBDOMAIN"

cat > "$NGINX_CONFIG" << NGINXEOF
# 🛰️ ServerTrack Satellites - nginx config for $SUBDOMAIN
# Generated: $(date)
# Campaign: $CAMPAIGN_ID | Landing Page: $LANDING_PAGE_ID

server {
    server_name $SUBDOMAIN;
    root /var/www/$SUBDOMAIN;
    index index.html;

    # Logging
    access_log /var/log/nginx/$SUBDOMAIN.access.log combined;
    error_log /var/log/nginx/$SUBDOMAIN.error.log warn;

    # Handle click tracking - forward to Voluum
    location /click/ {
        proxy_pass http://track.puritysalt.com;
        proxy_set_header Host track.puritysalt.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header User-Agent \$http_user_agent;
        proxy_redirect off;
        proxy_buffering off;
        
        # Logging for click tracking
        access_log /var/log/nginx/$SUBDOMAIN.clicks.log combined;
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
        
        # Inject parameters for Voluum tracking (stealth mode)
        sub_filter_once off;
        sub_filter '</head>' '<script>if(!window.location.search.includes("cpid")){history.replaceState(null,"","?\$final_args");}</script></head>';
        sub_filter_types text/html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Robots-Tag "noindex, nofollow" always;

    # Performance headers
    add_header Cache-Control "public, max-age=3600" always;
    
    # Custom header for identification
    add_header X-ServerTrack-Satellites "v2.0.0" always;
    add_header X-Campaign-ID "$CAMPAIGN_ID" always;

    listen 80;
}
NGINXEOF

if [ -f "$NGINX_CONFIG" ]; then
    log "nginx configuration created: $NGINX_CONFIG"
else
    error "Failed to create nginx configuration"
fi

# Test nginx configuration
step "Testing nginx configuration..."
if nginx -t 2>&1 | tee /tmp/nginx-test.log; then
    log "nginx configuration test passed"
else
    error "nginx configuration test failed. Check /tmp/nginx-test.log"
fi

# Enable site
step "Enabling nginx site..."
ENABLED_LINK="/etc/nginx/sites-enabled/$SUBDOMAIN"
if ln -sf "$NGINX_CONFIG" "$ENABLED_LINK"; then
    log "Site enabled: $ENABLED_LINK -> $NGINX_CONFIG"
else
    error "Failed to enable site"
fi

# Reload nginx
step "Reloading nginx..."
if systemctl reload nginx 2>&1 | tee /tmp/nginx-reload.log; then
    log "nginx reloaded successfully"
else
    error "nginx reload failed. Check /tmp/nginx-reload.log"
fi

# Attempt SSL certificate
step "Attempting SSL certificate generation..."
if certbot --nginx -d "$SUBDOMAIN" --non-interactive --agree-tos --email admin@puritysalt.com --redirect >/tmp/certbot.log 2>&1; then
    log "SSL certificate installed successfully"
    log "Site is now available at: https://$SUBDOMAIN"
else
    warn "SSL certificate generation failed (domain may not be ready)"
    log "Site is available at: http://$SUBDOMAIN"
    log "SSL can be added later when DNS propagates"
fi

# Final verification
step "Performing final verification..."
if [ -f "$SITE_DIR/index.html" ] && [ -f "$NGINX_CONFIG" ] && [ -L "$ENABLED_LINK" ]; then
    log "✅ Deployment verification passed"
    log "🌐 Landing page: $SITE_DIR/index.html"
    log "⚙️  nginx config: $NGINX_CONFIG"
    log "🔗 Enabled link: $ENABLED_LINK"
    log "📊 Campaign ID: $CAMPAIGN_ID"
    log "🎯 Landing Page ID: $LANDING_PAGE_ID"
    echo ""
    log "🎉 Satellite deployed successfully: $SUBDOMAIN"
else
    error "Deployment verification failed"
fi
EOF

chmod +x "$DEPLOY_SCRIPT"
if [ -x "$DEPLOY_SCRIPT" ]; then
    log "Deployment script created and made executable"
    verbose "Deployment script: $DEPLOY_SCRIPT"
else
    error "Failed to create deployment script"
fi

# Configure nginx default site
step "Configuring nginx default site..."
DEFAULT_CONFIG="/etc/nginx/sites-available/default"
verbose "Creating default nginx configuration..."

cat > "$DEFAULT_CONFIG" << EOF
# 🛰️ ServerTrack Satellites - Default nginx configuration
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    root /var/www/html;
    index index.html index.htm;

    # Custom status page
    location / {
        return 200 "🛰️ ServerTrack Satellites Server Ready!

📡 Server IP: $SERVER_IP
🌐 API Endpoint: http://$SERVER_IP:8080
🔍 Health Check: http://$SERVER_IP:8080/health
📊 Metrics: http://$SERVER_IP:8080/metrics
📋 Deployments: http://$SERVER_IP:8080/api/v1/landers

🚀 Deploy a campaign:
curl -X POST http://$SERVER_IP:8080/api/v1/lander \\
  -H 'Content-Type: application/json' \\
  -d '{\"campaign_id\":\"test\",\"landing_page_id\":\"lp1\",\"subdomain\":\"demo.puritysalt.com\"}'

🛰️ ServerTrack Satellites v2.0.0 - Ready for deployment!
";
        add_header Content-Type text/plain;
        add_header X-ServerTrack-Satellites "v2.0.0";
    }
    
    # API proxy for convenience
    location /api/ {
        proxy_pass http://127.0.0.1:8080/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Remove existing default and create new one
rm -f /etc/nginx/sites-enabled/default
if ln -sf "$DEFAULT_CONFIG" /etc/nginx/sites-enabled/default; then
    log "Default nginx site configured"
else
    error "Failed to configure default nginx site"
fi

# Start services
step "Starting and configuring services..."

# Start nginx
verbose "Starting nginx service..."
if systemctl start nginx 2>&1 | tee /tmp/nginx-start.log; then
    log "nginx service started successfully"
else
    error "Failed to start nginx service. Check /tmp/nginx-start.log"
fi

if systemctl is-active --quiet nginx; then
    log "nginx is running and active"
    verbose "nginx status: $(systemctl is-active nginx)"
else
    error "nginx service is not running"
fi

# Start ServerTrack Satellites
verbose "Starting ServerTrack Satellites API service..."
if systemctl start servertrack-satellites 2>&1 | tee /tmp/satellites-start.log; then
    log "ServerTrack Satellites service started"
else
    error "Failed to start ServerTrack Satellites service. Check /tmp/satellites-start.log"
fi

# Wait for startup and verify
step "Verifying service startup..."
verbose "Waiting 5 seconds for services to initialize..."
sleep 5

# Check nginx
if systemctl is-active --quiet nginx; then
    NGINX_PID=$(systemctl show nginx --property MainPID --value)
    log "nginx is active (PID: $NGINX_PID)"
else
    error "nginx service failed to start properly"
fi

# Check ServerTrack Satellites
if systemctl is-active --quiet servertrack-satellites; then
    SATELLITES_PID=$(systemctl show servertrack-satellites --property MainPID --value)
    log "ServerTrack Satellites is active (PID: $SATELLITES_PID)"
else
    warn "ServerTrack Satellites service may not be running"
    verbose "Service status: $(systemctl is-active servertrack-satellites || echo 'inactive')"
    verbose "Check logs: journalctl -u servertrack-satellites -n 20"
fi

# Test API endpoints
step "Testing API endpoints..."

# Health check
verbose "Testing health endpoint..."
if curl -s --connect-timeout 5 http://localhost:8080/health >/dev/null; then
    HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
    log "Health endpoint responding correctly"
    verbose "Health response: $HEALTH_RESPONSE"
else
    error "Health endpoint not responding. API may not be started correctly."
fi

# Test metrics endpoint
verbose "Testing metrics endpoint..."
if curl -s --connect-timeout 5 http://localhost:8080/metrics >/dev/null; then
    log "Metrics endpoint responding"
else
    warn "Metrics endpoint not responding"
fi

# Test deployment list
verbose "Testing landers endpoint..."
if curl -s --connect-timeout 5 http://localhost:8080/api/v1/landers >/dev/null; then
    log "Landers endpoint responding"
else
    warn "Landers endpoint not responding"
fi

# Final status report
echo ""
echo -e "${PURPLE}${BOLD}🎉 INSTALLATION COMPLETE - VERBOSE REPORT 🎉${NC}"
echo -e "${PURPLE}[$(date '+%Y-%m-%d %H:%M:%S')] Installation finished successfully${NC}"
echo ""

echo -e "${BOLD}📊 INSTALLATION SUMMARY:${NC}"
echo -e "🛰️ ServerTrack Satellites API: ${GREEN}✅ Running${NC}"
echo -e "🌐 nginx Web Server: ${GREEN}✅ Running${NC}"
echo -e "🔧 systemd Services: ${GREEN}✅ Enabled${NC}"
echo -e "📁 Templates Created: ${GREEN}✅ Ready${NC}"
echo -e "🚀 Deployment Script: ${GREEN}✅ Available${NC}"
echo ""

echo -e "${BOLD}🌐 ACCESS INFORMATION:${NC}"
echo -e "📡 Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "🔍 Health Check: ${GREEN}http://$SERVER_IP:8080/health${NC}"
echo -e "📊 Metrics: ${GREEN}http://$SERVER_IP:8080/metrics${NC}"
echo -e "📋 Deployments: ${GREEN}http://$SERVER_IP:8080/api/v1/landers${NC}"
echo -e "🌐 Default Page: ${GREEN}http://$SERVER_IP${NC}"
echo ""

echo -e "${BOLD}🚀 TEST DEPLOYMENT:${NC}"
echo -e "${CYAN}curl -X POST http://$SERVER_IP:8080/api/v1/lander \\${NC}"
echo -e "${CYAN}  -H 'Content-Type: application/json' \\${NC}"
echo -e "${CYAN}  -d '{\"campaign_id\":\"test-$(date +%s)\",\"landing_page_id\":\"lp-demo\",\"subdomain\":\"test.puritysalt.com\"}'${NC}"
echo ""

echo -e "${BOLD}📋 MONITORING COMMANDS:${NC}"
echo -e "🔍 Service Status: ${CYAN}sudo systemctl status servertrack-satellites${NC}"
echo -e "📊 Live Logs: ${CYAN}sudo journalctl -u servertrack-satellites -f${NC}"
echo -e "🌐 nginx Status: ${CYAN}sudo systemctl status nginx${NC}"
echo -e "⚙️  nginx Test: ${CYAN}sudo nginx -t${NC}"
echo ""

echo -e "${BOLD}📁 IMPORTANT LOCATIONS:${NC}"
echo -e "📦 Binary: ${CYAN}/opt/servertrack-satellites/servertrack-satellites${NC}"
echo -e "⚙️  Service: ${CYAN}/etc/systemd/system/servertrack-satellites.service${NC}"
echo -e "🌐 nginx Config: ${CYAN}/etc/nginx/sites-available/${NC}"
echo -e "📄 Templates: ${CYAN}/var/www/template/${NC}"
echo -e "🚀 Deploy Script: ${CYAN}/root/templates/deploy.sh${NC}"
echo -e "📝 Logs: ${CYAN}/var/log/nginx/ & journalctl${NC}"
echo ""

echo -e "${GREEN}✨ ServerTrack Satellites is fully operational and ready for campaign deployments! ✨${NC}"

# Log installation completion
log "Installation completed at $(date)"
log "Total installation time: ${SECONDS} seconds"