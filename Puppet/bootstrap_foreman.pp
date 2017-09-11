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
  command => 'mkdir -p /usr/local/etc/pkg/repos',
  creates => '/usr/local/etc/pkg/repos',
}

# Ensure the installation location in /opt (we're installing Foreman outside of system management's way)
zfs { 'opt':
  ensure     => 'present',
  name       => 'zroot/opt',
  mountpoint => '/opt',
}

file { '/opt':
  ensure  => 'directory',
  owner   => 'root',
  group   => 'wheel',
  mode    => '755',
  require => Zfs['opt'],
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