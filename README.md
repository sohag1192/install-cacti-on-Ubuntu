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

