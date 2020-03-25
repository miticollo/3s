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
  add-apt-repository -y -n ppa:phpmyadmin/ppa

  add-apt-repository -y -n "deb http://repo.mysql.com/apt/ubuntu/ $codename mysql-8.0"
  wget -qO - https://repo.mysql.com//RPM-GPG-KEY-mysql | apt-key add -

  add-apt-repository -y -n ppa:dns/gnu
  add-apt-repository -y -n ppa:ubuntu-toolchain-r/ppa
  add-apt-repository -y -n ppa:maxmind/ppa
  add-apt-repository -y -n ppa:jdstrand/ufw-daily
  add-apt-repository -y -n ppa:jonathonf/vim
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
  apt -y install mysql-server
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
