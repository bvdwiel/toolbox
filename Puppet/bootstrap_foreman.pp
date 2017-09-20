# Use Puppet Apply to install Foreman on FreeBSD 11.x
#-----
$foremanbranch = '1.16-stable'
$packages = [
  'www/node',
  'www/npm',
  'devel/git',
  'devel/libvirt',
  'sysutils/rubygem-bundler',
  'rubygem-pkg-config',
  'databases/postgresql95-client',
  'databases/sqlite3',
  'databases/mysql56-client',
  'devel/pkgconf',
  'lang/phantomjs',
  'archivers/zopfli',
  'textproc/libsass',
  'textproc/sassc',
  'lang/gcc' ]

# Use the latest packages from FreeBSD's binary repository
exec { 'create_pkg_repodir':
  path    => '/',
  command => '/bin/mkdir -p /usr/local/etc/pkg/repos',
  creates => '/usr/local/etc/pkg/repos',
}

file { '/opt':
  ensure  => 'directory',
  owner   => 'root',
  group   => 'wheel',
  mode    => '755',
}

file { '/usr/local/etc/pkg/repos/FreeBSD.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'wheel',
  mode    => '0644',
  source  => 'https://raw.githubusercontent.com/bvdwiel/toolbox/master/Puppet/FreeBSD.conf',
  require => Exec['create_pkg_repodir'],
}

package { $packages:
  ensure  => 'latest',
  require => File['/usr/local/etc/pkg/repos/FreeBSD.conf'],
}

# Put the source code of Foreman in /opt/foreman
exec { 'checkout_foreman_sources':
  cwd     => '/opt',
  command => "/usr/local/bin/git clone https://github.com/theforeman/foreman.git -b ${foremanbranch}",
  creates => '/opt/foreman',
  require => [ Package[$packages], File['/opt'] ]
}

# Ensure the settings.yaml file
file { 'settings.yaml':
  path    => '/opt/foreman/config/settings.yaml',
  owner   => 'root',
  group   => 'wheel',
  source  => 'https://raw.githubusercontent.com/bvdwiel/toolbox/master/Puppet/settings.yaml',
  require => Exec['checkout_foreman_sources'],
}

# Ensure the database.yml file
file { 'database.yml':
  path    => '/opt/foreman/config/database.yml',
  owner   => 'root',
  group   => 'wheel',
  source  => 'https://raw.githubusercontent.com/bvdwiel/toolbox/master/Puppet/database.yml',
  require => Exec['checkout_foreman_sources'],
}

# Install required Ruby gems
exec { 'install_rubygems':
  cwd     => '/opt/foreman',
  path    => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin',
  command => '/usr/local/bin/bundle install --without test --path vendor',
  creates => '/opt/foreman/vendor/ruby',
  timeout => 0,
  require => File['database.yml', 'settings.yaml'],
}

# Perform the npm install task
exec { 'npm_install':
  cwd     => '/opt/foreman',
  path    => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin',
  command => 'env CC=gcc5 CXX=g++5 /usr/local/bin/npm install',
  timeout => 0,
  creates => '/opt/foreman/node_modules',
  require => Exec['install_rubygems'],
}

# Database migration
exec { 'migrate_database':
  cwd     => '/opt/foreman',
  path    => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin',
  command => 'env RAILS_ENV=production bundle exec rake db:migrate',
  timeout => 0,
  creates => '/opt/foreman/db/production.sqlite3',
  notify  => Exec['seed_database'],
  require => Exec['npm_install'],
}

# Compile web assets
exec { 'compile_web_assets':
  cwd     => '/opt/foreman',
  path    => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin',
  command => 'env RAILS_ENV=production /usr/local/bin/bundle exec rake assets:precompile locale:pack webpack:compile',
  timeout => 0,
  creates => '/opt/foreman/public/assets',
  require => Exec['npm_install'],
}

# Seed the database
exec { 'seed_database':
  cwd         => '/opt/foreman',
  path        => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin',
  command     => 'env RAILS_ENV=production /usr/local/bin/bundle exec rake db:seed',
  timeout     => 0,
  refreshonly => true,
  require     => Exec['migrate_database'],
}

# Notify user of required action to get initial admin login
notify { 'generate_admin_user':
  message =>
    'Run from /opt/foreman/ and check the output of: env RAILS_ENV=production bundle exec rake permissions:reset',
  require => Exec['seed_database'],
}
