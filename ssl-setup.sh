#!/bin/bash

# SSL Setup Script for ServerTrack Satellites
# Configures dynamic SSL provisioning and nginx wildcard routing

echo "🔒 Setting up SSL provisioning for ServerTrack Satellites..."

# Copy SSL provisioning scripts from local directory if available
if [ -f "./provision-ssl.sh" ]; then
    cp ./provision-ssl.sh /usr/local/bin/provision-ssl.sh
    echo "✅ Copied provision-ssl.sh"
else
    echo "⚠️  provision-ssl.sh not found locally, creating basic version"
fi

if [ -f "./setup-dynamic-nginx.sh" ]; then
    cp ./setup-dynamic-nginx.sh /usr/local/bin/setup-dynamic-nginx.sh
    echo "✅ Copied setup-dynamic-nginx.sh"
else
    echo "⚠️  setup-dynamic-nginx.sh not found locally"
fi

if [ -f "./dynamic-wildcard-nginx.conf" ]; then
    cp ./dynamic-wildcard-nginx.conf /etc/nginx/sites-available/dynamic-wildcard
    echo "✅ Copied dynamic-wildcard-nginx.conf"
else
    echo "⚠️  dynamic-wildcard-nginx.conf not found locally"
fi

# Make scripts executable
chmod +x /usr/local/bin/provision-ssl.sh 2>/dev/null
chmod +x /usr/local/bin/setup-dynamic-nginx.sh 2>/dev/null

# Create basic SSL provisioning script if not exists
if [ ! -f /usr/local/bin/provision-ssl.sh ]; then
    cat > /usr/local/bin/provision-ssl.sh << 'EOFSSL'
#!/bin/bash

# Basic SSL Provisioning Script
DOMAIN="$1"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain.com>"
    exit 1
fi

echo "🔒 Provisioning SSL certificate for $DOMAIN"

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "✅ Certificate for $DOMAIN already exists"
    exit 0
fi

# Create certbot directory
mkdir -p /var/www/certbot

# Get SSL certificate using certbot with webroot
certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@$DOMAIN \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate obtained successfully for $DOMAIN"
else
    echo "❌ Failed to obtain SSL certificate for $DOMAIN"
    exit 1
fi
EOFSSL
    chmod +x /usr/local/bin/provision-ssl.sh
fi

echo "✅ SSL provisioning setup completed!"
echo ""
echo "📋 Usage:"
echo "  provision-ssl.sh yourdomain.com    # Provision SSL for domain"
echo "  setup-dynamic-nginx.sh             # Setup dynamic nginx config"
echo ""
echo "🔗 The ServerTrack Satellites API will automatically provision SSL"
echo "   certificates when deploying landing pages to new domains."