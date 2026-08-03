#!/bin/bash
# Apache SSL Setup & Redirect Script for Cacti
# Author: Md. Sohag Rana

set -e

DOMAIN="graph.yourdomin.com"
ADMIN_EMAIL="admin@$DOMAIN"
CONF_FILE="/etc/apache2/sites-available/cacti.conf"

echo "=== Installing Certbot and Apache Plugin ==="
sudo apt-get update -y
sudo apt-get install certbot python3-certbot-apache -y

echo "=== Enabling Apache SSL and Rewrite modules ==="
sudo a2enmod ssl rewrite

echo "=== Requesting SSL certificates with Certbot ==="
# Using 'certonly' so Certbot fetches the certs using the current Apache config 
# without automatically creating a messy vhost file.
sudo certbot certonly --apache -d "$DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"

echo "=== Creating SSL VirtualHost & Redirects for $DOMAIN ==="
cat <<EOF | sudo tee "$CONF_FILE"
<VirtualHost *:80>
    ServerName $DOMAIN
    
    # Redirect all port 80 (HTTP) traffic to port 443 (HTTPS)
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot /var/www/html

    # Auto-redirect the root domain to the /cacti/ subdirectory
    RedirectMatch ^/$ /cacti/

    # SSL Configuration (using Let's Encrypt certs)
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem

    # Cacti Directory Configuration
    Alias /cacti /var/www/html/cacti

    <Directory /var/www/html/cacti>
        Options +FollowSymLinks
        AllowOverride None
        Require all granted

        AddType application/x-httpd-php .php

        <IfModule mod_php.c>
            php_flag magic_quotes_gpc Off
            php_flag short_open_tag On
            php_flag register_globals Off
            php_flag register_argc_argv On
            php_flag track_vars On
            # this setting is necessary for some locales
            php_value mbstring.func_overload 0
            php_value include_path .
        </IfModule>

        DirectoryIndex index.php
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
EOF

echo "=== Enabling the new SSL configuration ==="
# Safely disable the default and any old configurations without crashing the script
sudo a2dissite 000-default.conf cacti-ssl.conf 2>/dev/null || true
sudo a2ensite cacti.conf

echo "=== Restarting Apache ==="
sudo systemctl restart apache2

echo "=== SSL Setup Complete! ==="
echo "You can now access your Cacti server securely at: https://$DOMAIN"
