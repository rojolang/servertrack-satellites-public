#!/bin/bash

# Auto SSL Provisioning Script for individual subdomains
# Usage: ./provision-ssl.sh subdomain.domain.com

FQDN="$1"

if [ -z "$FQDN" ]; then
    echo "Usage: $0 <subdomain.domain.com>"
    echo "Example: $0 demo.puritysalt.com"
    exit 1
fi

echo "🔒 Provisioning SSL certificate for $FQDN"

# Create certbot directory
mkdir -p /var/www/certbot

# Check if certificate already exists
if [ -d "/etc/letsencrypt/live/$FQDN" ]; then
    echo "✅ Certificate for $FQDN already exists"
    
    # Create nginx config for this specific domain
    cat > "/etc/nginx/sites-available/$FQDN" << EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    
    server_name $FQDN;
    
    ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    root /var/www/$FQDN;
    index index.html index.htm;
    
    # Handle click tracking
    location /click/ {
        proxy_pass http://track.\$(echo $FQDN | cut -d. -f2-);
        proxy_set_header Host track.\$(echo $FQDN | cut -d. -f2-);
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header User-Agent \$http_user_agent;
        proxy_redirect off;
        proxy_buffering off;
        access_log /var/log/nginx/$FQDN.clicks.log combined;
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header Cache-Control "public, max-age=3600" always;
    
    access_log /var/log/nginx/$FQDN.access.log combined;
    error_log /var/log/nginx/$FQDN.error.log warn;
}

server {
    listen 80;
    listen [::]:80;
    
    server_name $FQDN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    # Enable the site
    ln -sf "/etc/nginx/sites-available/$FQDN" "/etc/nginx/sites-enabled/$FQDN"
    
    # Test and reload nginx
    nginx -t && systemctl reload nginx
    echo "✅ SSL already configured for $FQDN"
    exit 0
fi

# Get SSL certificate using certbot with webroot
echo "🔐 Obtaining SSL certificate for $FQDN..."

# First create a temporary basic config for the domain to handle ACME challenges
cat > "/etc/nginx/sites-available/$FQDN" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $FQDN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        return 200 'SSL provisioning in progress...';
        add_header Content-Type text/plain;
    }
}
EOF

# Enable the temporary site
ln -sf "/etc/nginx/sites-available/$FQDN" "/etc/nginx/sites-enabled/$FQDN"
nginx -t && systemctl reload nginx

# Get the certificate
certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@$(echo $FQDN | cut -d. -f2-) \
    --agree-tos \
    --no-eff-email \
    -d "$FQDN"

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate obtained successfully!"
    
    # Now create the full SSL configuration
    cat > "/etc/nginx/sites-available/$FQDN" << EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    
    server_name $FQDN;
    
    ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    root /var/www/$FQDN;
    index index.html index.htm;
    
    # Handle click tracking
    location /click/ {
        proxy_pass http://track.\$(echo $FQDN | cut -d. -f2-);
        proxy_set_header Host track.\$(echo $FQDN | cut -d. -f2-);
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header User-Agent \$http_user_agent;
        proxy_redirect off;
        proxy_buffering off;
        access_log /var/log/nginx/$FQDN.clicks.log combined;
    }
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header Cache-Control "public, max-age=3600" always;
    
    access_log /var/log/nginx/$FQDN.access.log combined;
    error_log /var/log/nginx/$FQDN.error.log warn;
}

server {
    listen 80;
    listen [::]:80;
    
    server_name $FQDN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files \$uri =404;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOF

    # Test and reload nginx
    nginx -t && systemctl reload nginx
    echo "🎉 SSL provisioning completed for $FQDN!"
else
    echo "❌ Failed to obtain SSL certificate"
    rm -f "/etc/nginx/sites-enabled/$FQDN"
    rm -f "/etc/nginx/sites-available/$FQDN"
    systemctl reload nginx
    exit 1
fi