#!/usr/bin/env sh

set -e

codename=$(lsb_release -cs)

update() {
  apt clean all && \
  apt update && \
  apt -y full-upgrade && \
  apt -y autoremove
}

overwrite_sources_list () {
  apt -y install software-properties-common

  mv /etc/apt/sources.list /etc/apt/sources.list.bak

  apt-add-repository -y -n "deb http://archive.ubuntu.com/ubuntu/ $codename main restricted universe multiverse"
  apt-add-repository -y -n "deb http://security.ubuntu.com/ubuntu $codename-security main restricted universe multiverse"
  apt-add-repository -y -n "deb http://archive.ubuntu.com/ubuntu/ $codename-updates main restricted universe multiverse"
  apt-add-repository -y -n "deb http://archive.ubuntu.com/ubuntu $codename-backports main restricted universe multiverse"
  apt-add-repository -y -n "deb http://archive.canonical.com/ubuntu $codename partner"
}

add_extra_repos () {
  add-apt-repository -y -n ppa:adiscon/v8-stable
  add-apt-repository -y -n ppa:isc/bind
  LC_ALL=C.UTF-8 add-apt-repository -y -n ppa:ondrej/apache2
  LC_ALL=C.UTF-8 add-apt-repository -y -n ppa:ondrej/php
  add-apt-repository -y -n ppa:phpmyadmin/ppa

  add-apt-repository -y -n "deb http://repo.mysql.com/apt/ubuntu/ $codename mysql-8.0"
  wget -qO - https://repo.mysql.com//RPM-GPG-KEY-mysql | apt-key add -

  add-apt-repository -y -n ppa:dns/gnu
  add-apt-repository -y -n ppa:ubuntu-toolchain-r/ppa
  add-apt-repository -y -n ppa:maxmind/ppa
  add-apt-repository -y -n ppa:jdstrand/ufw-daily
  add-apt-repository -y -n ppa:jonathonf/vim
  add-apt-repository -y -n ppa:jonathonf/microcode
}

set_ssh_user () {
  USSH='ussh'
  useradd -c 'SSH user' -M -N -s /bin/bash $USSH
  echo "$USSH:pippo00" | chpasswd
}

config_sshd () {
  nano /etc/ssh/sshd_config
  systemctl -l restart sshd
}

config_static_ip () {
  nano /etc/netplan/01-netcfg.yaml
  netplan --debug apply
}

install_wordpress () {

  requirements () {
    BASIC_PKGS='php libapache2-mod-php mysql-server'

    WORDPRESS_PHP_EXTENSIONS='php-mysql php-common php-date php-xml php-gd php-gettext php-imagick php-imap php-intl php-json'
    WORDPRESS_PHP_EXTENSIONS="$WORDPRESS_PHP_EXTENSIONS php-libsodium php-mbstring php-memcache php-ssh2 php-sodium php-tokenizer php-zip"

    WOOCOMMERCE_PHP_EXTENSIONS='php-apcu php-bcmath php-gmp php-soap'

    # shellcheck disable=SC2086
    apt -y install $BASIC_PKGS $WORDPRESS_PHP_EXTENSIONS $WOOCOMMERCE_PHP_EXTENSIONS 'phpmyadmin'
  }

  download () {
    cd /tmp/
    wget https://it.wordpress.org/latest-it_IT.tar.gz -O 'latest.tar.gz'
    tar xvzf 'latest.tar.gz' -C /opt/
    chown -R www-data:www-data /opt/wordpress/
    cd -
    mv /opt/wordpress/wp-config-sample.php /opt/wordpress/wp-config.php
  }

  config_apache () {
    nano /etc/apache2/sites-available/wordpress.conf
    a2ensite wordpress
    a2enmod rewrite
    service apache2 reload
  }

  last_step () {
    clear
    echo "Open MySQL Workbench to config DB"
  }

  requirements
  download
  config_apache
  mysql_secure_installation
  last_step
}

main() {
  overwrite_sources_list
  add_extra_repos
  update
  set_ssh_user
  config_sshd
  config_static_ip
  install_wordpress
}

main
