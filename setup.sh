#!/bin/bash

# Nginx configuration
config="server {
  listen 80;
  server_name localhost;
  index index.php;
  root /var/www/beruvm/web;
  location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
  }
  location ~ \\.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
  }
  location ~ \\.ht {
    deny all;
  }
}"

# Update repositories
apt update -y

# Install requirements
apt install -y nginx git unzip php7.2-fpm php7.2-cli php7.2-mysql php7.2-mbstring php7.2-gd php7.2-curl php7.2-zip php7.2-xml mysql-server python-pip && pip install --upgrade setuptools && pip install spur pysphere crypto netaddr
 
# Random password
password=$(openssl rand -base64 16)

# PHP config
php_config="<?php
return [
    'class' => 'yii\db\Connection',
    'dsn' => 'mysql:host=localhost;dbname=beruvm',
    'username' => 'beruvm',
    'password' => '$password',
    'charset' => 'utf8',
];"

# Configure MySQL
mysql -u root -e "CREATE USER beruvm@localhost IDENTIFIED WITH mysql_native_password BY '$password';GRANT ALL PRIVILEGES ON *.* TO beruvm@localhost; FLUSH PRIVILEGES;CREATE DATABASE beruvm DEFAULT CHARACTER SET utf8;"

# Configure Nginx
sed -i 's/# multi_accept on/multi_accept on/' /etc/nginx/nginx.conf && echo $config > /etc/nginx/sites-available/default && service nginx restart

# Configure PHP
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/7.2/fpm/php.ini && service php7.2-fpm restart

# Configure beruvm
cd /var/www && rm -rf html && git clone https://github.com/umyz-sh/beruvm && cd beruvm && php7.2 composer.phar install && echo $php_config > /var/www/beruvm/config/db.php && mysql -u root -proot beruvm < database.sql && mysql -u root -e "USE beruvm;UPDATE user SET auth_key = '$password'" && php7.2 yii migrate --interactive=0 && chmod -R 0777 /var/www/beruvm

# Configure Cron
cd /tmp && echo -e "*/5 * * * * php /var/www/beruvm/yii cron/index\n0 0 * * * php /var/www/beruvm/yii cron/reset" > cron && crontab cron

# Find address
address=$(ip address | grep "scope global" | grep -Po '(?<=inet )[\d.]+')

# Update Yii2
cd /var/www/beruvm
rm -rf vendor/yiisoft/yii2/*
wget https://github.com/yiisoft/yii2/archive/refs/heads/master.zip
unzip master.zip
cp -r yii2-master/* vendor/yiisoft/yii2/
rm -rf yii2-master master.zip

 
# MySQL details
clear && echo -e "\033[104mThe platform installation has been completed successfully.\033[0m\n\nMySQL information:\nUsername: beruvm\nDatabase: beruvm\nPassword: \033[0;32m$password\033[0m\n\n\nLogin information:\nAddress: http://$address\nUsername: admin@admin.com\nPassword: admin\n\nAttention: Please run \033[0;31mmysql_secure_installation\033[0m for the security"

