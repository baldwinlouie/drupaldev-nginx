
# Make sure puppet group exists
group { 'puppet': ensure => present }

# Add following directories to users path
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }

# Set server variables from yaml file
$server_values = hiera('server', false)

# Ensure packages defined in common.yaml are installed
ensure_packages( $server_values['packages'] )

# Don't run apt-get update
class {'apt':
  always_apt_update => false,
}

# Install RVM
class { 'rvm': version => '1.25.7' }

# Make sure RVMs system user is vagrant
rvm::system_user { vagrant: }

# Install nginx
class { 'nginx': }

# Get all configuration info from nginx.yaml
$nginx = hiera('nginx', false)

# Install PHP with custom settings
class { 'php':
  package             => 'php5-fpm',
  service             => 'php5-fpm',
  service_autorestart => false,
  config_file         => '/etc/php5/fpm/php.ini',
  module_prefix       => '',
  require             => Class["apt"],
}

# Install php modules defined in nginx.yaml
php::module {
  [
    $nginx['phpmodules']
  ]:
  notify  => Service["php5-fpm"]
}

# Make sure php5-fpm is always running
service { 'php5-fpm':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['php5-fpm'],
}

# Install PHP Devel package
class { 'php::devel':
  require => Class['php'],
}

# Install PHP Pear
class { 'php::pear':
  require => Class['php'],
}

# Install xdebug
class { 'xdebug':
  service => 'nginx',
}

# Install composer
#class { 'composer':
#  require => Package['php5-fpm', 'curl'],
#}

# Install mysql server and set root password
class { '::mysql::server':
  root_password => 'drupaldev'
}

# install latest drush, which installs composer. Not the best
class {'drush::git::drush':
  git_tag => '6.5.0',
  update     => true,
}

# Install Pear package console table
php::pear::module { 'Console_Table':
  use_package => 'no',
}

# Set php ini values from nginx.yaml
php::ini { 'php.ini':
  value => $nginx['phpini'],
  config_dir => '/etc/php5',
  sapi_target => 'fpm',
  require => Package["php5-fpm"]
}

file { "/tmp/php": ensure => "directory"}

# Build site values for provision of site specific things
if $site_values == undef {
  $site_values = hiera('sites', false)
}

if count($site_values['vhosts']) > 0 {
  create_resources(nginx_vhost, $site_values['vhosts'])
}

if is_hash($site_values['databases']) and count($site_values['databases']) > 0 {
  create_resources(mysql_db, $site_values['databases'])
}

# Template for installing a nginx vhost
define nginx_vhost (
  $server_name,
  $server_aliases = [],
  $www_root,
  $listen_port,
  $index_files,
  $envvars = [],
  ){
  $merged_server_name = concat([$server_name], $server_aliases)

  if is_array($index_files) and count($index_files) > 0 {
    $try_files = $index_files[count($index_files) - 1]
  } else {
    $try_files = 'index.php'
  }

  nginx::resource::vhost { $server_name:
    server_name => $merged_server_name,
    www_root    => $www_root,
    listen_port => $listen_port,
    index_files => $index_files,
    try_files   => ['$uri', '$uri/', "/${try_files}?\$args"],
  }

  nginx::resource::location { "${server_name}-php":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.php$',
    proxy               => undef,
    try_files           => ['$uri', '$uri/', "/${try_files}?\$args"],
    www_root            => $www_root,
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => 'PATH_INFO $fastcgi_path_info',
      'fastcgi_param '           => 'PATH_TRANSLATED $document_root$fastcgi_path_info',
      'fastcgi_param  '           => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
      'fastcgi_pass'            => 'unix:/var/run/php5-fpm.sock',
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params'
    },
    notify              => Class['nginx::service'],
  }

  file { $www_root:
    ensure => "directory",
  }
}

# Template for instaling a mysql db
define mysql_db (
  $user,
  $password,
  $host,
  $grant    = [],
  $sql_file = false
  ) {
    if $name == '' or $password == '' or $host == '' {
    fail( 'MySQL DB requires that name, password and host be set. Please check your settings!' )
  }

  mysql::db { $name:
    user     => $user,
    password => $password,
    host     => $host,
    grant    => $grant,
    sql      => $sql_file,
  }
}

# Install automysqlbackup and set default folder
class { 'automysqlbackup':
  backup_dir           => '/home/vagrant/db'
}

#Fix for php5sock not being writable
file_line {'sock1':
  path => '/etc/php5/fpm/pool.d/www.conf',
  line => 'listen.owner = www-data',
  ensure => present,
  require => Package['php5-fpm'],
}
file_line {'sock2':
  path => '/etc/php5/fpm/pool.d/www.conf',
  line => 'listen.group = www-data',
  ensure => present,
  require => Package['php5-fpm'],
}
file_line {'sock3':
  path => '/etc/php5/fpm/pool.d/www.conf',
  line => 'listen.mode = 0660',
  ensure => present,
  notify => Service["php5-fpm"],
  require => Package['php5-fpm'],
}
