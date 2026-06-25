#!/bin/bash
# ============================================================
# Cacti Installer Script for Ubuntu/Linux
# Author: Md. Sohag Rana (adapted for automation)
# ============================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define database credentials for automation
DB_USER="cactiuser"
DB_PASS="cactiuser"
DB_NAME="cacti"

echo "🔧 Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "📦 Installing dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y snmp php-snmp rrdtool librrds-perl unzip curl git gnupg2

echo "🌐 Installing LAMP stack (Apache, MariaDB, PHP)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 mariadb-server php php-mysql libapache2-mod-php \
    php-xml php-ldap php-mbstring php-gd php-gmp php-intl

echo "📝 Configuring PHP..."
# Get PHP version cleanly
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

for ini in /etc/php/${PHP_VERSION}/apache2/php.ini /etc/php/${PHP_VERSION}/cli/php.ini; do
    if [ -f "$ini" ]; then
        sed -i 's/^memory_limit.*/memory_limit = 512M/' "$ini"
        sed -i 's/^max_execution_time.*/max_execution_time = 60/' "$ini"
        sed -i 's@^;date.timezone.*@date.timezone = Asia/Dhaka@' "$ini"
        sed -i 's@^date.timezone.*@date.timezone = Asia/Dhaka@' "$ini" # Ensure it changes if uncommented
    fi
done
systemctl restart apache2

echo "🗄️ Configuring MariaDB..."
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF

# Custom Cacti settings
collation-server = utf8mb4_unicode_ci
character-set-server = utf8mb4
max_heap_table_size = 512M
tmp_table_size = 512M
join_buffer_size = 1024M
innodb_file_format = Barracuda
innodb_large_prefix = 1
innodb_buffer_pool_size = 1G
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 32
innodb_write_io_threads = 32
innodb_io_capacity = 5000
innodb_io_capacity_max = 10000
# innodb_buffer_pool_instances = 50 # Removed: Too high for 1G pool size, can cause MariaDB to crash on lower RAM systems.
innodb_doublewrite = OFF
EOF

systemctl restart mariadb

echo "🗄️ Creating Cacti database and user..."
# Using mysql command without password prompt since we are root running the script
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

echo "⏱️ Importing timezone data..."
mysql mysql < /usr/share/mysql/mysql_test_data_timezone.sql
mysql -e "GRANT SELECT ON mysql.time_zone_name TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "⬇️ Downloading Cacti..."
wget -qO cacti-latest.tar.gz https://www.cacti.net/downloads/cacti-latest.tar.gz
tar -zxf cacti-latest.tar.gz
rm cacti-latest.tar.gz
# Ensure clean move by removing default index if necessary
rm -f /var/www/html/index.html
# Move the extracted directory contents to /var/www/html/cacti
mv cacti-1* /var/www/html/cacti

echo "📂 Importing Cacti database schema..."
mysql ${DB_NAME} < /var/www/html/cacti/cacti.sql

echo "⚙️ Configuring Cacti..."
# Copy the config file from the sample
cp /var/www/html/cacti/include/config.php.dist /var/www/html/cacti/include/config.php
CONFIG_FILE="/var/www/html/cacti/include/config.php"

sed -i "s/\$database_default = 'cacti';/\$database_default = '${DB_NAME}';/" $CONFIG_FILE
sed -i "s/\$database_hostname = 'localhost';/\$database_hostname = 'localhost';/" $CONFIG_FILE
sed -i "s/\$database_username = 'cactiuser';/\$database_username = '${DB_USER}';/" $CONFIG_FILE
sed -i "s/\$database_password = 'cactiuser';/\$database_password = '${DB_PASS}';/" $CONFIG_FILE
sed -i "s/\$database_port = '3306';/\$database_port = '3306';/" $CONFIG_FILE

echo "🔒 Setting permissions..."
touch /var/www/html/cacti/log/cacti.log
chown -R www-data:www-data /var/www/html/cacti/
chmod -R 775 /var/www/html/cacti/rra/
chmod -R 775 /var/www/html/cacti/log/

echo "⏲️ Setting up Cacti cron job..."
# Fixed the 'nano >' issue. Cat is the correct command for writing to a file in a script.
cat > /etc/cron.d/cacti <<EOF
*/5 * * * * www-data php /var/www/html/cacti/poller.php > /dev/null 2>&1
EOF

echo "🌐 Configuring Apache Virtual Host for Cacti..."
# Disable default site to avoid conflicts if needed, or set up a dedicated conf.
a2dissite 000-default.conf || true

cat > /etc/apache2/sites-available/cacti.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/cacti

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
            php_value mbstring.func_overload 0
            php_value include_path .
        </IfModule>

        DirectoryIndex index.php
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2ensite cacti
systemctl reload apache2

# Get the server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "========================================================"
echo "✅ Cacti installation and configuration complete!"
echo "👉 Access Cacti at: http://${SERVER_IP}/"
echo "🔑 Default Login: admin / admin"
echo "========================================================"
