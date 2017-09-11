#!/bin/sh
sed -i -e 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf
pkg update
pkg upgrade
pkg install -y www/node www/npm devel/git devel/libvirt sysutils/rubygem-bundler rubygem-pkg-config databases/postgresql95-client databases/sqlite3 databases/mysql56-client devel/pkgconf lang/phantomjs archivers/zopfli textproc/libsass textproc/sassc lang/gcc
cd /root
git clone https://github.com/theforeman/foreman.git -b 1.16-stable
cd foreman
cp config/settings.yaml.example config/settings.yaml
cp config/database.yml.example config/database.yml
bundle install --without test --path vendor
env CC=gcc5 CXX=g++5 npm install node-gyp -g
env CC=gcc5 CXX=g++5  npm install
env RAILS_ENV=production bundle exec rake db:migrate
env RAILS_ENV=production bundle exec rake db:seed assets:precompile locale:pack webpack:compile

