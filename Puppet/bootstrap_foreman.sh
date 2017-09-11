#!/bin/sh
sed -i -e 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf
pkg update
pkg upgrade -y
pkg install -y sysutils/puppet4
puppet apply ./bootstrap_foreman.pp
