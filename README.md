
<div align="center">

# 📊 Cacti Network Monitoring: Ubuntu Installation Guide

![Visitors Badge](https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fsohag1192%2Finstall-cacti-on-Ubuntu%2F&label=Visitors&icon=github&color=%23198754&message=&style=for-the-badge&tz=UTC)

[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![MySQL](https://img.shields.io/badge/MySQL-005C84?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net/)
[![Apache](https://img.shields.io/badge/Apache-D22128?style=for-the-badge&logo=apache&logoColor=white)](https://httpd.apache.org/)

*A comprehensive, automated guide to installing and configuring Cacti (with Spine Poller & WeatherMap) on Ubuntu for enterprise-grade network monitoring.*

</div>

---

## 📖 Overview

[Cacti](https://www.cacti.net/) is a robust, open-source operational monitoring and fault management framework. As a Network Engineer, deploying Cacti allows you to harness the power of RRDTool to graph network bandwidth, CPU usage, and hardware metrics via SNMP.

This repository provides a production-ready **automated installation script (`install.sh`)** alongside manual deployment instructions for **Ubuntu 20.04/22.04 LTS**, utilizing the LAMP stack (Linux, Apache, MariaDB/MySQL, PHP). 

---

## 🔑 What’s Inside the Repository

* **`README.md`**: The comprehensive documentation you are reading now.
* **`install.sh`**: A shell script that automates the entire Cacti installation process, including:
    * Updating system packages.
    * Installing all required dependencies (`snmp`, `php-snmp`, `rrdtool`, etc.).
    * Deploying Apache, MariaDB, PHP, and necessary PHP extensions (`php-mysql`, `php-gd`, `php-gmp`, etc.).
    * Configuring `php.ini` (`memory_limit`, `max_execution_time`, `date.timezone`).
    * Tuning MariaDB for Cacti performance (buffer pool, I/O threads).
    * Creating the Cacti database and user (`cactiuser` / `cactiuser`).
    * Downloading, extracting, and configuring the latest Cacti release.
    * Setting strict directory permissions and configuring the polling cron job.
    * Configuring the Apache VirtualHost to serve `/cacti` directly.

---

## 🚀 Quick Setup: Automated Installation

The fastest way to deploy Cacti is using the provided shell script.

### 1. Clone the repository
```bash
git clone https://github.com/sohag1192/install-cacti-on-Ubuntu.git
cd install-cacti-on-Ubuntu

```

### 2. Make the script executable

```bash
chmod +x install.sh

```

### 3. Run the script as root

```bash
sudo ./install.sh

```

* *Note: You will be prompted for the MariaDB root password during the database setup phase.*
* *Note: The script defaults the timezone to **Asia/Dhaka**. You can modify this inside `install.sh` prior to running.*

### 4. Access the Cacti Web UI

* Open your web browser and navigate to your server's IP address: `http://<your-server-ip>/`
* **Default Login:** `admin` / `admin` (You will be forced to change this upon first login).

---

## 🛠 Manual Installation & Optimization Steps

If you prefer to install Cacti manually, follow the comprehensive steps below.

### Step 1: Update System & Install LAMP Stack

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y apache2 mariadb-server mariadb-client \
    php php-mysql libapache2-mod-php php-xml php-ldap php-mbstring \
    php-gd php-gmp php-curl php-intl \
    snmp php-snmp snmpd rrdtool git curl

```

### Step 2: Configure the MariaDB Database

```bash
sudo mysql_secure_installation
sudo mysql -u root -p

CREATE DATABASE cacti DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON cacti.* TO 'cactiuser'@'localhost' IDENTIFIED BY 'cactiuser';
GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;

```

Import the timezones to your database:

```bash
mysql -u root -p mysql < /usr/share/mysql/mysql_test_data_timezone.sql

```

### Step 3: Optimize MariaDB

Edit the MariaDB config file (`sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf`) and add the following under `[mysqld]`:

```ini
collation-server = utf8mb4_unicode_ci
character-set-server = utf8mb4
max_heap_table_size = 128M
tmp_table_size = 64M
join_buffer_size = 64M
innodb_file_format = Barracuda
innodb_large_prefix = 1
innodb_buffer_pool_size = 1G
innodb_flush_log_at_timeout = 3
innodb_read_io_threads = 32
innodb_write_io_threads = 16
innodb_io_capacity = 5000
innodb_io_capacity_max = 10000

```

Restart MariaDB: `sudo systemctl restart mariadb`

### Step 4: Configure PHP

Edit `php.ini` for both Apache (`/etc/php/*/apache2/php.ini`) and CLI (`/etc/php/*/cli/php.ini`):

```ini
memory_limit = 512M
max_execution_time = 60
date.timezone = Asia/Dhaka

```

Restart Apache: `sudo systemctl restart apache2`

### Step 5: Install Cacti

```bash
wget [https://www.cacti.net/downloads/cacti-latest.tar.gz](https://www.cacti.net/downloads/cacti-latest.tar.gz)
tar -zxvf cacti-latest.tar.gz
sudo mv cacti-* /var/www/html/cacti
sudo mysql -u cactiuser -p cacti < /var/www/html/cacti/cacti.sql

```

Update `$database_username` and `$database_password` in `sudo nano /var/www/html/cacti/include/config.php`.

### Step 6: Set Permissions & Configure Cron

```bash
sudo chown -R www-data:www-data /var/www/html/cacti/
sudo chmod -R 775 /var/www/html/cacti/rra/
sudo chmod -R 775 /var/www/html/cacti/log/
sudo nano /etc/cron.d/cacti

```

Add to cron (polls every 5 minutes):

```bash
*/5 * * * * www-data php /var/www/html/cacti/poller.php > /dev/null 2>&1

```

---

## ⚡ High-Performance: Installing Cacti Spine (Optional)

For enterprise networks, the multi-threaded C-based Spine poller is highly recommended over the default `cmd.php`.

```bash
sudo apt install -y build-essential autoconf automake dos2unix help2man libmysqlclient-dev libssl-dev libsnmp-dev libtool
wget [https://www.cacti.net/downloads/spine/cacti-spine-latest.tar.gz](https://www.cacti.net/downloads/spine/cacti-spine-latest.tar.gz)
tar -zxvf cacti-spine-latest.tar.gz
cd cacti-spine-*/
./bootstrap
./configure
make
sudo make install
sudo cp /usr/local/spine/etc/spine.conf.dist /usr/local/spine/etc/spine.conf

```

Update database credentials in `sudo nano /usr/local/spine/etc/spine.conf`.
Finally, in the Cacti Web UI, go to **Configuration -> Settings -> Poller** and change the Poller Type to **Spine**.

---

## 🗺️ Step-by-Step Installation of WeatherMap Plugin

The Network Weathermap plugin allows you to overlay Cacti graphs onto custom network topological diagrams.

### 1. Navigate to Cacti plugins directory

```bash
cd /var/www/html/cacti/plugins

```

### 2. Download WeatherMap plugin

```bash
git clone [https://github.com/Cacti/plugin_weathermap.git](https://github.com/Cacti/plugin_weathermap.git) weathermap

```

### 3. Set proper permissions

```bash
chown -R www-data:www-data /var/www/html/cacti/plugins/weathermap
chmod -R 755 /var/www/html/cacti/plugins/weathermap

```

### 4. Verify PHP modules

WeatherMap requires `gd` and `pcre` PHP modules. Ensure they are installed:

```bash
sudo apt-get install php-gd php-pcre -y
sudo systemctl restart apache2

```

### 5. Enable the plugin in Cacti

1. Log in to the Cacti Web UI as an administrator.
2. Navigate to **Console → Configuration → Plugins**.
3. Locate **WeatherMap** in the list.
4. Click the **Install** action, and then click **Enable**.

### 6. Create Maps

Once enabled, the **WeatherMap Editor** menu will appear in Cacti. You can use this editor to build graphical network maps, assign data sources (SNMP, RRDTool), and customize backgrounds, links, and icons.

**Notes on WeatherMap:**

* Compatible with **Cacti 1.x upwards**.
* Maps are highly customizable and can be embedded directly into Cacti dashboards or exported for reporting.

---

## 🤝 Contribution & Support

*If you found this Cacti installation script and guide helpful for your NOC operations, please consider giving it a star! ⭐️*

**Developed by [Md Sohag Rana](https://github.com/sohag1192) - ISP Automation Architect & Network Engineer**
