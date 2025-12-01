![Badge](https://hitscounter.dev/api/hit?url=https%3A%2F%2Fgithub.com%2Fsohag1192%2Finstall-cacti-on-Ubuntu%2F&label=Visitors&icon=github&color=%23198754&message=&style=for-the-badge&tz=UTC)

## 🔑 What’s Inside the Repository
- **README.md**: Documentation explaining how to install and activate the Cacti server.  
- **install.sh**: A shell script that automates the installation process. It includes:
  - Updating system packages  
  - Installing dependencies (`snmp`, `php-snmp`, `rrdtool`, `librrds-perl`, etc.)  
  - Installing Apache, MariaDB, PHP, and required extensions (`php-mysql`, `php-xml`, `php-mbstring`, `php-gd`, `php-gmp`, `php-intl`)  
  - Configuring PHP (`memory_limit`, `max_execution_time`, `date.timezone`)  
  - Tuning MariaDB for Cacti performance (buffer pool, I/O threads, etc.)  
  - Creating the Cacti database and user (`cactiuser` / `cactiuser`)  
  - Downloading and extracting the latest Cacti release  
  - Importing the Cacti schema into MariaDB  
  - Setting permissions and cron jobs for polling  
  - Configuring Apache VirtualHost so `/cacti` is served directly  

---

## 🛠 How to Use the Script

1. **Clone the repository**
   ```bash
   git clone https://github.com/sohag1192/install-cacti-on-Ubuntu.git
   cd install-cacti-on-Ubuntu
   ```

2. **Make the script executable**
   ```bash
   chmod +x install.sh
   ```

3. **Run the script as root**
   ```bash
   sudo ./install.sh
   ```

   - You’ll be prompted for the MariaDB root password during database setup.  
   - The script sets timezone to **Asia/Dhaka** by default (you can adjust inside `install.sh`).  

4. **Access Cacti Web UI**
   - Open your browser and go to:
     ```
     http://<your-server-ip>/
     ```
   - Default login: `admin` / `admin` (you’ll be asked to change the password).  

---

## ✅ Outcome
After running the script, you’ll have a fully configured **Cacti monitoring server** on Ubuntu, with Apache serving `/cacti` as the default web root.  

---



---

## 🛠 Step-by-Step Installation of WeatherMap Plugin

1. **Navigate to Cacti plugins directory**
   ```bash
   cd /var/www/html/cacti/plugins
   ```

2. **Download WeatherMap plugin**
   ```bash
   git clone https://github.com/Cacti/plugin_weathermap.git weathermap
   ```

3. **Set permissions**
   ```bash
   chown -R www-data:www-data /var/www/html/cacti/plugins/weathermap
   chmod -R 755 /var/www/html/cacti/plugins/weathermap
   ```

4. **Enable plugin in Cacti**
   - Log in to Cacti web UI as admin.
   - Go to **Console → Configuration → Plugins**.
   - You should see **WeatherMap** listed.
   - Click **Install** and then **Enable**.

5. **Verify PHP modules**
   - WeatherMap requires `gd` and `pcre` PHP modules.
   - Install if missing:
     ```bash
     sudo apt-get install php-gd php-pcre -y
     sudo systemctl restart apache2
     ```

6. **Create maps**
   - After enabling, you’ll see a **WeatherMap Editor** menu in Cacti.
   - Use it to draw network maps, add links, icons, and configure data sources (SNMP, RRDTool, etc.).

---




---

## 🔑 Notes
- Works with **Cacti 1.x upwards**.  
- Maps can be customized with icons, backgrounds, colors, and labels.  
- Output can be embedded in dashboards or exported for reports.  

---

