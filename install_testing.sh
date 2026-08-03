#!/bin/bash
# ============================================================
# Cacti Latest Version Installer Script (1.2.31)
# Ubuntu 20.04/22.04 LTS
# Author: Md. Sohag Rana (automation adapted)
# ============================================================

set -e

# Database credentials
DB_USER="cactiuser"
DB_PASS="cactiuser"
DB_NAME="cacti"

echo "🔧 Updating system packages..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "📦 Installing dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y snmp snmpd php-snmp rrdtool librrds-perl unzip curl git gnupg2

echo "🌐 Installing LAMP stack (Apache, MariaDB, PHP)..."
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 mariadb-server \
    php php-mysql libapache2-mod-php php-xml php-ldap php-mbstring php-gd php-gmp php-intl php-json php-curl

echo "📝 Configuring PHP..."
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
for ini in /etc/php/${PHP_VERSION}/apache2/php.ini /etc/php/${PHP_VERSION}/cli/php.ini; do
    if [ -f "$ini" ]; then
        sed -i 's/^memory_limit.*/memory_limit = 512M/' "$ini"
        sed -i 's/^max_execution_time.*/max_execution_time = 60/' "$ini"
        sed -i 's@^;date.timezone.*@date.timezone = Asia/Dhaka@' "$ini"
        sed -i 's@^date.timezone.*@date.timezone = Asia/Dhaka@' "$ini"
    fi
done
systemctl restart apache2

echo "🗄️ Configuring MariaDB..."
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF

# Custom Cacti settings
[mysqld]
collation-server = utf8mb4_unicode_ci
character-set-server = utf8mb4
max_heap_table_size = 512M
tmp_table_size = 512M
join_buffer_size = 1024M
innodb_buffer_pool_size = 1024M
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_io_capacity = 1000
innodb_io_capacity_max = 2000
innodb_doublewrite = OFF
EOF

systemctl restart mariadb

echo "🗄️ Creating Cacti database and user..."
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

echo "⏱️ Importing timezone data..."
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
mysql -e "GRANT SELECT ON mysql.time_zone_name TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "⬇️ Downloading Cacti Latest Version (1.2.31)..."
wget -qO cacti-latest.tar.gz https://www.cacti.net/downloads/cacti-latest.tar.gz
tar -zxf cacti-latest.tar.gz
rm cacti-latest.tar.gz
rm -f /var/www/html/index.html
mv cacti-1* /var/www/html/cacti

echo "📂 Importing Cacti database schema..."
mysql ${DB_NAME} < /var/www/html/cacti/cacti.sql

echo "⚙️ Configuring Cacti..."
cp /var/www/html/cacti/include/config.php.dist /var/www/html/cacti/include/config.php
CONFIG_FILE="/var/www/html/cacti/include/config.php"
sed -i "s/\$database_default = 'cacti';/\$database_default = '${DB_NAME}';/" $CONFIG_FILE
sed -i "s/\$database_username = 'cactiuser';/\$database_username = '${DB_USER}';/" $CONFIG_FILE
sed -i "s/\$database_password = 'cactiuser';/\$database_password = '${DB_PASS}';/" $CONFIG_FILE

echo "🔒 Setting permissions..."
touch /var/www/html/cacti/log/cacti.log
chown -R www-data:www-data /var/www/html/cacti/
chmod -R 775 /var/www/html/cacti/rra/
chmod -R 775 /var/www/html/cacti/log/

echo "⏲️ Setting up Cacti cron job..."
cat > /etc/cron.d/cacti <<EOF
*/5 * * * * www-data php /var/www/html/cacti/poller.php > /dev/null 2>&1
EOF

echo "🌐 Configuring Apache (default site only)..."
# Just serve Cacti from /var/www/html/cacti without separate cacti.conf
sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/cacti|' /etc/apache2/sites-available/000-default.conf

systemctl reload apache2

SERVER_IP=$(hostname -I | awk '{print $1}')

echo "========================================================"
echo "✅ Cacti Latest Version (1.2.31) installation complete!"
echo "👉 Access Cacti at: http://${SERVER_IP}/"
echo "🔑 Default Login: admin / admin"
echo "========================================================"
