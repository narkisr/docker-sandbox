group{ 'puppet': ensure  => present }

node default {


  class{'docker':
    tcp_bind  => 'tcp://0.0.0.0:4243'
  }

  docker::image { 'ubuntu':
    tag => 'precise'
  }

  class{'nginx':
    manage_repo => false
  }

  file { '/etc/ssl/nginx':
    ensure => directory,
    owner  => $nginx::params::nx_daemon_user,
    mode   => '750',
  } ->

  exec{'/root/.rnd':
    command => 'echo `< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c100` > /root/.rnd',
    user    => 'root',
    path    => ['/usr/bin','/bin',]
  } ->

  file { '/root/.rnd':
    ensure => present,
    mode   => '600',
    owner  => 'root',
  } ->

  openssl::certificate::x509 { $fqdn:
    ensure       => present,
    country      => 'US',
    organization => 'Big',
    unit         => 'The Punisher Unit',
    state        => 'Foo',
    locality     => 'Bar',
    commonname   => '192.168.1.30',
    email        => 'bla@foo.com',
    days         => 3456,
    base_dir     => '/etc/ssl/nginx',
    force        => true,
    owner        => $nginx::params::nx_daemon_user,
  } ->

  nginx::resource::upstream { "${fqdn}-upstream":
    ensure  => present,
    members => ["localhost:4243"],
  } ->

  nginx::resource::vhost { $fqdn:
    ensure      => present,
    listen_port => 443,
    ssl         => true,
    ssl_cert    => "/etc/ssl/nginx/${fqdn}.crt",
    ssl_key     => "/etc/ssl/nginx/${fqdn}.key",
    proxy       => "http://${fqdn}-upstream",
  }
}
