#!/bin/bash

# Update package list
sudo apt update

# Install Ruby
sudo apt-get -y update && apt-get install -y ruby-full
sudo ruby -v
sudo gem -v

# Install Utilities
sudo apt-get install -y curl unzip build-essential nano wget mcrypt
sudo apt-get -qq update && apt-get -qq -y install bzip2
sudo apt-get install -y chrpath libssl-dev libxft-dev
sudo apt-get install -y libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev

# Install ppa:ondrej/php PPA
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update

# Install Apache2 and PHP
sudo apt-get update && apt-get install -y apache2
sudo apt-get install -y php-pear libapache2-mod-php8.0
sudo apt-get install -y php8.0-common php8.0-cli
sudo apt-get install -y php8.0-bz2 php8.0-zip php8.0-curl php8.0-gd php8.0-mysql php8.0-xml php8.0-dev php8.0-sqlite php8.0-mbstring php8.0-bcmath
sudo php -v
sudo php -m

# Show PHP errors on development server.
sudo sed -i -e 's/^error_reporting\s*=.*/error_reporting = E_ALL/' /etc/php/8.0/apache2/php.ini
sudo sed -i -e 's/^display_errors\s*=.*/display_errors = On/' /etc/php/8.0/apache2/php.ini
sudo sed -i -e 's/^zlib.output_compression\s*=.*/zlib.output_compression = Off/' /etc/php/8.0/apache2/php.ini
sudo sed -i -e 's/^zpost_max_size\s*=.*/post_max_size = 32M/' /etc/php/8.0/apache2/php.ini
sudo sed -i -e 's/^upload_max_filesize\s*=.*/upload_max_filesize = 32M/' /etc/php/8.0/apache2/php.ini


# Install MySQL Server
sudo apt install -y mysql-server

# Install phpMyAdmin
sudo apt install -y phpmyadmin

# Configure phpMyAdmin to use with Apache2
sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
sudo a2enconf phpmyadmin
sudo systemctl restart apache2

# Purge old PHP
sudo apt-get update
sudo apt-get -y purge '^php7.4.*'
sudo php -v

# Install Git
sudo apt-get install -y git
sudo git --version

# Install SASS & Compass
sudo gem install sass
sudo gem install compass
sudo gem install css_parser

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Composer
sudo apt-get install -y php-cli
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo HASH="$(wget -q -O - https://composer.github.io/installer.sig)" && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# Install WordPress
sudo mkdir /var/www/html/wordpress
cd /tmp
wget -c https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo cp -r wordpress/* /var/www/html/wordpress
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Install Nextcloud
sudo mkdir /var/www/html/nextcloud
cd /tmp
wget -c https://download.nextcloud.com/server/releases/latest.tar.bz2
tar -xjvf latest.tar.bz2
sudo cp -r nextcloud/* /var/www/html/nextcloud
sudo chown -R www-data:www-data /var/www/html/nextcloud
sudo chmod -R 755 /var/www/html/nextcloud

# Configure Apache2 for WordPress
sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/wordpress
    ServerName your-wordpress-domain.com
    ServerAlias www.your-wordpress-domain.com
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Configure Apache2 for Nextcloud
sudo tee /etc/apache2/sites-available/nextcloud.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/nextcloud
    ServerName your-nextcloud-domain.com
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable Apache2 modules and virtual hosts
sudo a2ensite wordpress.conf
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Start MySQL service
sudo systemctl start mysql

# Prompt user to set MySQL root password
echo "Please enter a password for MySQL root user:"
sudo mysql_secure_installation

# Inform user that the installation is complete
echo "Installation is complete. You can now access WordPress at your-wordpress-domain.com and Nextcloud at your-nextcloud-domain.com"
