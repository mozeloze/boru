#!/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: lamp-ubuntu1804.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 22-02-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: Ubuntu 18.04
#
# PURPOSE: This script installs a LAMP stack on an Ubuntu 18.04 system
#
# REV LIST:
# DATE: 14-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 14-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Let's update Ubuntu's local repositories on this box.
apt update -y

# Let's upgrade the already installed packages on this box.
apt upgrade -y

# Enable port 22 for SSH connections on the firewall prior to firing it up
ufw allow 22

# Install Expect so the MySQL secure installation process can be automated.
apt install -y expect

# Let's enable port 22 (for the SSH service) on the UFW firewall.

ENABLE_UFW_22=$(expect -c "
set timeout 2
spawn ufw enable
expect \"Command may disrupt existing ssh connections. Proceed with operation (y|n)?\"
send \"y\r\"
expect eof
")
echo "ENABLE_UFW_22"

# Let's enable the ports for a web server on the firewall
ufw allow 80
ufw allow 443

# Let's install Apache HTTP
apt install -y apache2

# Set the ServerName directive in the main configuration file
echo 'ServerName localhost' >> /etc/apache2/apache2.conf

# Let's install MariaDB database.
apt install -y mariadb-server

# Make the hideous 'safe' install for MySQL.Remember Debian people make  the root MariaDB user 
# to authenticate using the unix_socket plugin by default rather than with a password.
# Setting a password here is useless. For more info visit the following links:
# https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-9
# https://mariadb.com/kb/en/differences-in-mariadb-in-debian-and-ubuntu/
# https://mariadb.com/kb/en/authentication-plugin-unix-socket/
# Crucial to understand this situation on Debian installs: 
# The unix_socket authentication plugin allows the user to use operating system credentials 
# when connecting to MariaDB via the local Unix socket file. This Unix socket file is defined by the socket system variable.
# This basically means the root user from the system is the one able to log in as root into the MariaDB.

SECURE_MYSQL=$(expect -c "
set timeout 2
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"Bloody_hell_doN0t\r\"
expect \"Set root password? \[Y/n\]\"
send \"n\r\"
expect \"Remove anonymous users? \[Y/n\]\"
send \"y\r\"
expect \"Disallow root login remotely? \[Y/n\]\"
send \"y\r\"
expect \"Remove test database and access to it? \[Y/n\]\"
send \"y\r\"
expect \"Reload privilege tables now? \[Y/n\]\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"

# Install PHP
apt install -y php libapache2-mod-php php-mysql

# Edit the dir.conf file inside the modules-enabled directory for Apache HTTP
# to understand PHP's parlance.
sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

# Restart Apache HTTP with Systemd's systemctl command.
systemctl reload apache2

# Let's create a directory dedicated to a VirtualHost for one website.
mkdir /var/www/example.com

# Let's make that directory owned by the Apache HTTP user on Debian
chown -R www-data:www-data  /var/www/example.com

# Create the VirtualHost configuration file for that website.
touch /etc/apache2/sites-available/example.com.conf

# Add the VirtualHost configuration into the file
echo "
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com 
    ServerAdmin youremailgmail.com
    DocumentRoot /var/www/example.com
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/example.com.conf

# Enable the just created site.
a2ensite example.com

# Reload Apache HTTP with the new configuration on the new website
systemctl reload apache2

# Test PHP
# First we create a php file
touch /var/www/example.com/info.php

# Second we add a simple PHP script so it will display information about the site.
echo "<?php phpinfo(); ?>" >> /var/www/example/info.php

# Remove the info.php file once you've tested the site.

# We are done. Finish announcement.
echo "The LAMP stack has been installed"

# Sources:
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mariadb-php-lamp-stack-on-debian-10
# https://www.adminbyaccident.com/gnu-linux/lamp-stack-debian/
