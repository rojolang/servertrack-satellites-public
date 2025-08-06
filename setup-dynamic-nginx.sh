#!/bin/bash

# Setup Dynamic Nginx Configuration
echo "🌐 Setting up dynamic nginx configuration..."

# Backup existing nginx configuration
echo "📦 Backing up existing nginx configuration..."
cp -r /etc/nginx/sites-available /etc/nginx/sites-available.backup.$(date +%Y%m%d_%H%M%S)
cp -r /etc/nginx/sites-enabled /etc/nginx/sites-enabled.backup.$(date +%Y%m%d_%H%M%S)

# Remove existing site configurations to avoid conflicts
echo "🧹 Cleaning up existing site configurations..."
rm -f /etc/nginx/sites-enabled/*
rm -f /etc/nginx/sites-available/default

# Install the dynamic wildcard configuration
echo "⚙️ Installing dynamic wildcard configuration..."
cp /root/dynamic-wildcard-nginx.conf /etc/nginx/sites-available/dynamic-wildcard
ln -sf /etc/nginx/sites-available/dynamic-wildcard /etc/nginx/sites-enabled/

# Create log directory if it doesn't exist
mkdir -p /var/log/nginx

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Reload nginx
    echo "🔄 Reloading nginx..."
    systemctl reload nginx
    
    echo "🎉 Dynamic nginx configuration setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Run SSL provisioning: ./ssl-provisioning-script.sh yourdomain.com"
    echo "2. Deploy landing pages to /var/www/subdomain.yourdomain.com/"
    echo "3. Test with: curl -H 'Host: test.yourdomain.com' https://yourserver/"
else
    echo "❌ Nginx configuration error. Rolling back..."
    rm -f /etc/nginx/sites-enabled/dynamic-wildcard
    rm -f /etc/nginx/sites-available/dynamic-wildcard
    
    # Restore a basic default if needed
    echo "server { listen 80 default_server; root /var/www/html; }" > /etc/nginx/sites-available/default
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    
    systemctl reload nginx
    echo "❌ Setup failed. Please check nginx error logs."
    exit 1
fi