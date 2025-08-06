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
TRACKING_DOMAIN="${4:-track.puritysalt.com}"

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <subdomain> <campaign_id> <landing_page_id> [tracking_domain]"
    echo "Example: $0 demo.puritysalt.com camp-123 lp-456"
    echo "Example: $0 demo.puritysalt.com camp-123 lp-456 custom.track.domain.com"
    exit 1
fi

step "🛰️ Deploying satellite: $SUBDOMAIN"
log "Campaign ID: $CAMPAIGN_ID"
log "Landing Page ID: $LANDING_PAGE_ID"
log "Tracking Domain: $TRACKING_DOMAIN"

# Create site directory
step "Creating site directory structure..."
SITE_DIR="/var/www/$SUBDOMAIN"
if mkdir -p "$SITE_DIR"; then
    log "Site directory created: $SITE_DIR"
else
    error "Failed to create site directory: $SITE_DIR"
fi

# Copy template files
step "Copying fresh landing page template from GitHub..."
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
        proxy_pass http://$TRACKING_DOMAIN;
        proxy_set_header Host $TRACKING_DOMAIN;
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
