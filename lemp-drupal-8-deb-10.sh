#!/bin/bash
export DRUPAL_VER=9.2.5
export PHP_VER=7.3
export BASE_DIR=`pwd`

apt-get update -y
apt-get -y install git curl wget supervisor openssh-server locales beanstalkd python3 python3-pip libleptonica-dev tesseract-ocr libtesseract-dev \
mysql-client mysql-server apache2 pwgen vim-tiny mc iproute2 python-setuptools \
unison netcat net-tools memcached nano php php-cli php-common \
php-gd php-json php-mbstring php-xdebug php-mysql php7.3-opcache php-curl \
php-readline php-xml php-memcached php-oauth php-bcmath \

pip3 install BeautifulSoup4 lxml pillow pytesseract

apt-get -y clean autoclean autoremove
rm -rf /var/lib/apt/lists/*

mkdir -p /var/log/supervisor

echo "export VISIBLE=now" >> /etc/profile; \
rm -rf /var/lib/mysql/*; /usr/sbin/mysqld --initialize-insecure; \
sed -i 's/^bind-address/#bind-address/g' /etc/mysql/mysql.conf.d/mysqld.cnf; \
sed -i "s/Basic Settings/Basic Settings\ndefault-authentication-plugin=mysql_native_password\n/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Install Composer, drush and drupal console
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Drupal new version, clean cache
curl https://updates.drupal.org/release-history/drupal/${DRUPAL_VER} -o /tmp/latest.xml

# Retrieve drupal & adminer
# TODO: also require drupal/memcache
cd /var/www/html; \
DV=$(curl -s https://git.drupalcode.org/project/drupal/-/tags?format=atom | grep -e '<title>' | grep -Eo '[0-9\.]+'|sort -nr | grep ^${DRUPAL_VER} | head -n1) \
&& git clone --depth 1 --single-branch -b ${DV} https://git.drupalcode.org/project/drupal.git web \
&& cd web; composer require drush/drush:~10; composer install  \
&& php --version; composer --version; vendor/bin/drush --version; vendor/bin/drush status \
&& cd /var/www/html; chmod a+w web/sites/default; \
mkdir web/sites/default/files; chown -R www-data:www-data /var/www/html/; \
chmod -R ug+w /var/www/html/ ; \
wget "http://www.adminer.org/latest.php" -O /var/www/html/web/adminer.php

# Install supervisor
echo $BASE_DIR
cd $BASE_DIR
cp ./files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
cp ./files/start.sh ./start.sh


# Set some permissions
mkdir -p /var/run/mysqld; \
chown mysql:mysql /var/run/mysqld; \

bash ./start.sh
