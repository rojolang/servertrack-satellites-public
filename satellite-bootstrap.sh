#!/bin/bash

# 🛰️ ServerTrack Satellite Server Bootstrap
# This script turns any Ubuntu server into a ServerTrack Satellite that receives API commands

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║               🛰️ ServerTrack Satellite Server 🛰️            ║"
echo "  ║                    Bootstrap Installer                       ║"
echo "  ║                                                              ║"
echo "  ║    Transforms this server into a campaign deployment         ║"
echo "  ║    satellite that receives API commands remotely             ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "💥 This script requires Ubuntu 22.04 or 24.04"
    exit 1
fi

echo -e "${BLUE}🛰️ Initializing satellite server...${NC}"

# Update system
echo -e "${BLUE}📡 Updating system packages...${NC}"
apt update -qq
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq

# Install essential packages
echo -e "${BLUE}📦 Installing satellite dependencies...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y -qq \
    curl wget git unzip tar \
    nginx certbot python3-certbot-nginx \
    jq htop net-tools \
    supervisor \
    fail2ban ufw \
    build-essential

# Install Go
echo -e "${BLUE}🔧 Installing Go runtime...${NC}"
if ! command -v go &> /dev/null; then
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
fi

# Download and install ServerTrack Satellites
echo -e "${BLUE}🚀 Installing ServerTrack Satellites API...${NC}"
cd /tmp

# Download the latest release (this would be from your GitHub releases)
SATELLITES_URL="https://github.com/rojolang/servertrack-satellites/releases/latest/download/servertrack-satellites-deploy.tar.gz"

# For now, we'll create the structure manually since we don't have GitHub releases yet
mkdir -p /opt/servertrack-satellites
mkdir -p /root/templates
mkdir -p /var/www/template

# Create the API binary placeholder (will be replaced by actual download)
echo -e "${BLUE}📁 Setting up satellite file structure...${NC}"

# Create basic landing page template
cat > /var/www/template/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Campaign Landing Page</title>
    <style>
        body { 
            font-family: 'Arial', sans-serif; 
            margin: 0; 
            padding: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 20px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
        }
        h1 { 
            color: #333; 
            font-size: 2.5em; 
            margin-bottom: 20px; 
        }
        p { 
            color: #666; 
            font-size: 1.2em; 
            margin-bottom: 30px; 
        }
        .btn { 
            background: linear-gradient(45deg, #FF6B6B, #4ECDC4); 
            color: white; 
            padding: 15px 30px; 
            text-decoration: none; 
            border-radius: 50px; 
            display: inline-block; 
            margin: 10px; 
            font-weight: bold;
            font-size: 1.1em;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        .btn:hover { 
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.3);
        }
        .satellite { 
            font-size: 3em; 
            margin-bottom: 20px; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="satellite">🛰️</div>
        <h1>Campaign Landing Page</h1>
        <p>Your beautiful campaign is now live and tracking with ServerTrack Satellites!</p>
        <p>All clicks are automatically tracked and optimized.</p>
        <a href="/click/1" class="btn">Get Started Now</a>
        <a href="/click/2" class="btn">Learn More</a>
        <a href="/click/3" class="btn">Special Offer</a>
    </div>

    <!-- ServerTrack Satellites tracking will be injected here -->
    <script>
        console.log('🛰️ ServerTrack Satellites - Campaign tracking active');
        console.log('Tracking parameters:', window.location.search);
        
        // Track page load
        if (typeof gtag !== 'undefined') {
            gtag('event', 'page_view', {
                'page_title': 'Campaign Landing Page',
                'page_location': window.location.href
            });
        }
    </script>
</body>
</html>
EOF

# Create deployment script template
cat > /root/templates/quick-deploy.sh << 'EOF'
#!/bin/bash
# ServerTrack Satellites - Campaign Deployment Script

set -e

SUBDOMAIN="$1"
CAMPAIGN_ID="$2"
LANDING_PAGE_ID="$3"

if [ $# -ne 3 ]; then
    echo "❌ Usage: $0 <subdomain> <campaign_id> <landing_page_id>"
    exit 1
fi

echo "🛰️ Deploying satellite campaign: $SUBDOMAIN"
echo "📊 Campaign ID: $CAMPAIGN_ID"
echo "🎯 Landing Page ID: $LANDING_PAGE_ID"

# Create website directory
mkdir -p "/var/www/$SUBDOMAIN"
cp -r /var/www/template/* "/var/www/$SUBDOMAIN/"

# Create nginx configuration with Voluum tracking
cat > "/etc/nginx/sites-available/$SUBDOMAIN" << NGINXEOF
server {
    server_name $SUBDOMAIN;
    root /var/www/$SUBDOMAIN;
    index index.html;

    # Handle Voluum click tracking
    location /click/ {
        proxy_pass http://track.puritysalt.com;
        proxy_set_header Host track.puritysalt.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
    }

    location / {
        # Campaign tracking configuration
        set \$campaign_id "$CAMPAIGN_ID";
        set \$lander_id "$LANDING_PAGE_ID";
        
        # Build tracking parameters
        set \$final_args "cpid=\$campaign_id&lpid=\$lander_id";
        if (\$args != "") {
            set \$final_args "\$final_args&\$args";
        }
        
        try_files \$uri \$uri/ /index.html;
        
        # Inject Voluum tracking parameters silently
        sub_filter_once off;
        sub_filter '</head>' '<script>if(!window.location.search.includes("cpid")){history.replaceState(null,"","?\$final_args");}</script></head>';
        sub_filter_types text/html;
    }

    # Security and performance headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    listen 80;
}
NGINXEOF

# Enable the site
ln -sf "/etc/nginx/sites-available/$SUBDOMAIN" "/etc/nginx/sites-enabled/$SUBDOMAIN"

# Test and reload nginx
if nginx -t; then
    systemctl reload nginx
    echo "✅ nginx configuration updated"
else
    echo "❌ nginx configuration error"
    exit 1
fi

# Attempt SSL certificate (non-blocking for domain setup)
echo "🔐 Setting up SSL certificate..."
if certbot --nginx -d "$SUBDOMAIN" --non-interactive --agree-tos --email admin@puritysalt.com --quiet; then
    echo "✅ SSL certificate installed for $SUBDOMAIN"
else
    echo "⚠️ SSL certificate setup skipped (domain may not be ready yet)"
fi

# Set proper permissions
chown -R www-data:www-data "/var/www/$SUBDOMAIN"
chmod -R 755 "/var/www/$SUBDOMAIN"

echo "🎉 Satellite campaign deployed successfully!"
echo "🌐 URL: https://$SUBDOMAIN"
echo "📊 Tracking: Voluum campaign $CAMPAIGN_ID, lander $LANDING_PAGE_ID"
EOF

chmod +x /root/templates/quick-deploy.sh

# Set up firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp

# Configure fail2ban
echo -e "${BLUE}🛡️ Setting up intrusion protection...${NC}"
systemctl enable fail2ban
systemctl start fail2ban

# Set up nginx
echo -e "${BLUE}🌐 Configuring nginx...${NC}"
systemctl enable nginx
systemctl start nginx

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Create satellite status page
cat > /etc/nginx/sites-available/satellite-status << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        return 200 '🛰️ ServerTrack Satellite Server Online

Status: Ready for campaign deployments
API: Port 8080 (when ServerTrack Satellites is running)

This server is configured as a ServerTrack Satellite and is ready to receive
campaign deployment commands via the API.

To deploy a campaign, send a POST request to:
http://this-server:8080/api/v1/lander

Example:
curl -X POST http://this-server:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '"'"'{"campaign_id":"camp-123","landing_page_id":"lp-456","subdomain":"demo.yourdomain.com"}'"'"'

For more information: https://github.com/rojolang/servertrack-satellites
';
        add_header Content-Type text/plain;
    }
}
EOF

ln -sf /etc/nginx/sites-available/satellite-status /etc/nginx/sites-enabled/satellite-status
systemctl reload nginx

# Get server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo -e "${PURPLE}${BOLD}🎉 SATELLITE SERVER READY! 🎉${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}🛰️ ServerTrack Satellite Server initialized successfully!${NC}"
echo ""
echo -e "${BOLD}📡 Server IP: ${GREEN}$SERVER_IP${NC}"
echo -e "${BOLD}🌐 Status Page: ${GREEN}http://$SERVER_IP${NC}"
echo ""
echo -e "${BOLD}📋 Next Steps:${NC}"
echo -e "1. ${CYAN}Download and install ServerTrack Satellites API binary${NC}"
echo -e "2. ${CYAN}Start the API service on port 8080${NC}"
echo -e "3. ${CYAN}Begin deploying campaigns via API calls${NC}"
echo ""
echo -e "${BOLD}🚀 To complete setup, run:${NC}"
echo -e "${CYAN}# Download ServerTrack Satellites (replace with actual download URL)${NC}"
echo -e "${CYAN}wget -O /opt/servertrack-satellites/servertrack-satellites https://github.com/rojolang/servertrack-satellites/releases/latest/download/servertrack-satellites${NC}"
echo -e "${CYAN}chmod +x /opt/servertrack-satellites/servertrack-satellites${NC}"
echo ""
echo -e "${BOLD}🔧 Or install complete package:${NC}"
echo -e "${CYAN}wget https://github.com/rojolang/servertrack-satellites/releases/latest/download/servertrack-satellites-deploy.tar.gz${NC}"
echo -e "${CYAN}tar xzf servertrack-satellites-deploy.tar.gz${NC}"
echo -e "${CYAN}cd servertrack-satellites-deploy && sudo bash install.sh${NC}"
echo ""
echo -e "${PURPLE}✨ Satellite server is configured and ready for campaign deployments! ✨${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
EOF

chmod +x /root/rojolang-api/satellite-bootstrap.sh