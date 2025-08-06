#!/bin/bash
# Simple ServerTrack Satellite Setup
# Just installs what's needed and gets the API running

set -e

echo "🛰️ Setting up ServerTrack Satellite..."

# Basic system update
apt update -qq
apt install -y curl wget nginx certbot python3-certbot-nginx jq

# Install Go
if ! command -v go &> /dev/null; then
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    rm go1.21.5.linux-amd64.tar.gz
fi

# Create directories
mkdir -p /opt/servertrack-satellites
mkdir -p /root/templates
mkdir -p /var/www/template

# Simple landing page template
cat > /var/www/template/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Campaign Landing</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .btn { background: #007cba; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 10px; display: inline-block; }
    </style>
</head>
<body>
    <h1>Campaign Landing Page</h1>
    <p>Your campaign is live and tracking.</p>
    <a href="/click/1" class="btn">Click Here 1</a>
    <a href="/click/2" class="btn">Click Here 2</a>
    <a href="/click/3" class="btn">Click Here 3</a>
</body>
</html>
EOF

# Simple deployment script
cat > /root/templates/quick-deploy.sh << 'EOF'
#!/bin/bash
set -e
SUBDOMAIN="$1"
CAMPAIGN_ID="$2"
LANDING_PAGE_ID="$3"

mkdir -p "/var/www/$SUBDOMAIN"
cp -r /var/www/template/* "/var/www/$SUBDOMAIN/"

cat > "/etc/nginx/sites-available/$SUBDOMAIN" << NGINXEOF
server {
    server_name $SUBDOMAIN;
    root /var/www/$SUBDOMAIN;
    index index.html;

    location /click/ {
        proxy_pass http://track.puritysalt.com;
        proxy_set_header Host track.puritysalt.com;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        set \$campaign_id "$CAMPAIGN_ID";
        set \$lander_id "$LANDING_PAGE_ID";
        set \$final_args "cpid=\$campaign_id&lpid=\$lander_id";
        if (\$args != "") {
            set \$final_args "\$final_args&\$args";
        }
        try_files \$uri \$uri/ /index.html;
        sub_filter_once off;
        sub_filter '</head>' '<script>if(!window.location.search.includes("cpid")){history.replaceState(null,"","?\$final_args");}</script></head>';
    }

    listen 80;
}
NGINXEOF

ln -sf "/etc/nginx/sites-available/$SUBDOMAIN" "/etc/nginx/sites-enabled/$SUBDOMAIN"
nginx -t && systemctl reload nginx
certbot --nginx -d "$SUBDOMAIN" --non-interactive --agree-tos --email admin@puritysalt.com --quiet || true
chown -R www-data:www-data "/var/www/$SUBDOMAIN"
echo "✅ Deployed: https://$SUBDOMAIN"
EOF

chmod +x /root/templates/quick-deploy.sh

# Simple systemd service
cat > /etc/systemd/system/servertrack-satellites.service << 'EOF'
[Unit]
Description=ServerTrack Satellites API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/servertrack-satellites
ExecStart=/opt/servertrack-satellites/servertrack-satellites
Restart=always
RestartSec=5
Environment=PORT=8080

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nginx
systemctl start nginx

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default

echo "✅ ServerTrack Satellite ready"
echo "📡 Server IP: $(curl -s ifconfig.me)"
echo "🔧 Next: Copy servertrack-satellites binary to /opt/servertrack-satellites/"
echo "🚀 Then: systemctl start servertrack-satellites"