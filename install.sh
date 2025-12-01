#!/bin/bash
# ============================================================
# Cacti Installer Script for Ubuntu/Linux
# Author: Md. Sohag Rana (adapted for automation)
# ============================================================

set -e

echo "🔧 Updating system packages..."
apt-get update -y
apt-get upgrade -y

echo "📦 Installing dependencies..."
apt-get install -y snmp php-snmp rrdtool librrds-perl unzip curl git gnupg2

echo "🌐 Installing LAMP stack (Apache, MariaDB, PHP)..."
apt-get install -y apache2 mariadb-server php php-mysql libapache2-mod-php \
    php-xml php-ldap php-mbstring php-gd php-gmp php-intl

echo "📝 Configuring PHP..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
for ini in /etc/php/${PHP_VERSION}/apache2/php.ini /etc/php/${PHP_VERSION}/cli/php.ini; do
    sed -i 's/^memory_limit.*/memory_limit = 512M/' $ini
    sed -i 's/^max_execution_time.*/max_execution_time = 60/' $ini
    sed -i 's@^;date.timezone.*@date.timezone = Asia/Dhaka@' $ini
done
systemctl restart apache2

echo "🗄️ Configuring MariaDB..."
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF

# Custom Cacti settings
collation-server = utf8mb4_unicode_ci
max_heap_table_size = 512M
tmp_table_size = 512M
join_buffer_size = 1024M
innodb_file_format = Barracuda
innodb_large_prefix = 1
innodb_buffer_pool_size = 16384M
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 32
innodb_write_io_threads = 32
innodb_io_capacity = 5000
innodb_io_capacity_max = 10000
innodb_buffer_pool_instances = 50
innodb_doublewrite = OFF
EOF

systemctl restart mariadb

echo "🗄️ Creating Cacti database and user..."
mysql -u root -p<<MYSQL_SCRIPT
CREATE DATABASE cacti;
GRANT ALL ON cacti.* TO 'cactiuser'@'localhost' IDENTIFIED BY 'cactiuser';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "⏱️ Importing timezone data..."
mysql mysql < /usr/share/mysql/mysql_test_data_timezone.sql
mysql -u root -p<<MYSQL_SCRIPT
GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "⬇️ Downloading Cacti..."
wget https://www.cacti.net/downloads/cacti-latest.tar.gz
tar -zxvf cacti-latest.tar.gz
mv cacti-1* /var/www/html/cacti

echo "📂 Importing Cacti database schema..."
mysql cacti < /var/www/html/cacti/cacti.sql

echo "⚙️ Configuring Cacti..."
CONFIG_FILE="/var/www/html/cacti/include/config.php"
sed -i "s/\$database_default.*/\$database_default = 'cacti';/" $CONFIG_FILE
sed -i "s/\$database_hostname.*/\$database_hostname = 'localhost';/" $CONFIG_FILE
sed -i "s/\$database_username.*/\$database_username = 'cactiuser';/" $CONFIG_FILE
sed -i "s/\$database_password.*/\$database_password = 'cactiuser';/" $CONFIG_FILE
sed -i "s/\$database_port.*/\$database_port = '3306';/" $CONFIG_FILE

touch /var/www/html/cacti/log/cacti.log
chown -R www-data:www-data /var/www/html/cacti/
chmod -R 775 /var/www/html/cacti/

echo "⏲️ Setting up Cacti cron job..."
nano > /etc/cron.d/cacti <<EOF
*/5 * * * * www-data php /var/www/html/cacti/poller.php > /dev/null 2>&1
EOF

echo "🌐 Configuring Apache Virtual Host for Cacti..."
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

echo "✅ Cacti installation and configuration complete!"
echo "👉 Access Cacti at: http://<your-server-ip>/"
