#!/bin/bash
# ============================================================
# Cacti Uninstaller Script for Ubuntu/Linux
# Author: Md. Sohag Rana (automation adapted)
# ============================================================

set -e

# Database credentials (must match your install script)
DB_USER="cactiuser"
DB_NAME="cacti"

echo "⚠️ Starting Cacti uninstallation..."

echo "🛑 Stopping Apache and MariaDB services..."
systemctl stop apache2 || true
systemctl stop mariadb || true

echo "🗑️ Removing Apache VirtualHost for Cacti..."
a2dissite cacti.conf || true
rm -f /etc/apache2/sites-available/cacti.conf
systemctl reload apache2 || true

echo "🗑️ Removing Cacti files..."
rm -rf /var/www/html/cacti

echo "🗑️ Removing Cacti cron job..."
rm -f /etc/cron.d/cacti

echo "🗄️ Dropping Cacti database and user..."
mysql -e "DROP DATABASE IF EXISTS ${DB_NAME};"
mysql -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "🧹 Removing Cacti dependencies (optional)..."
apt-get remove --purge -y snmp snmpd php-snmp rrdtool librrds-perl
apt-get autoremove -y
apt-get clean

echo "✅ Cacti has been completely uninstalled from your system."
