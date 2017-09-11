$packages [
  'editors/nano',
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

exec { 'create_pkg_repodir':
  path    => '/',
  command => 'mkdir -p /usr/local/etc/pkg/repos',
  creates => '/usr/local/etc/pkg/repos',
}

file { '/usr/local/etc/pkg/repos/FreeBSD.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'wheel',
  mode    => '0644',
  source  => 'https://raw.githubusercontent.com/bvdwiel/toolbox/master/Puppet/FreeBSD.conf'
  require => Exec['create_pkg_repodir'],
}

package { $packages:
  ensure  => 'latest',
  require => File['/usr/local/etc/pkg/repos/FreeBSD.conf'],
}

