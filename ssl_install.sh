#!/bin/bash
# Apache SSL Setup & Redirect Script for Cacti
# Author:  (for Md. Sohag Rana)

set -e

echo "=== Checking for Certbot ==="
if ! command -v certbot &> /dev/null; then
    echo "Certbot not found. Installing..."
    sudo apt update
    sudo apt install certbot python3-certbot-apache -y
else
    echo "Certbot is already installed."
fi

DOMAIN="graph.yourdomin.com"
DOCROOT="/var/www/html"
CACTIROOT="/var/www/html/cacti"
ADMIN_EMAIL="admin@$DOMAIN"

echo "=== Enabling Apache SSL and Rewrite modules ==="
sudo a2enmod ssl
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "=== Requesting SSL certificates with Certbot ==="
# Using 'certonly' so Certbot fetches the certs using the current Apache config 
# without automatically creating a messy vhost file.
sudo certbot certonly --apache -d $DOMAIN --non-interactive --agree-tos -m $ADMIN_EMAIL

echo "=== Creating SSL VirtualHost & Redirects for $DOMAIN ==="
cat <<EOF | sudo tee /etc/apache2/sites-available/cacti-ssl.conf
<VirtualHost *:80>
    ServerName $DOMAIN
    
    # Redirect all insecure HTTP traffic to the secure Cacti URL
    Redirect permanent / https://$DOMAIN/cacti/
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $DOCROOT

    # Redirect the root domain (https://$DOMAIN/) directly to /cacti/
    RedirectMatch ^/$ /cacti/

    Alias /cacti $CACTIROOT

    <Directory $CACTIROOT>
        Options +FollowSymLinks
        AllowOverride None
        Require all granted
        DirectoryIndex index.php
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem

    ErrorLog \${APACHE_LOG_DIR}/cacti_ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/cacti_ssl_access.log combined
</VirtualHost>
EOF

echo "=== Disabling default HTTP site to prevent conflicts ==="
sudo a2dissite 000-default.conf || true

echo "=== Enabling new SSL/Redirect site ==="
sudo a2ensite cacti-ssl.conf
sudo systemctl reload apache2 || true

echo "=== Setting up auto-renewal ==="
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo "=== Setup completed successfully! ==="
echo "Any visit to $DOMAIN will now securely redirect to: https://$DOMAIN/cacti/"
