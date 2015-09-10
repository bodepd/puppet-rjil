#
# profile for configuring keystone role
#
class rjil::keystone(
  $admin_email            = 'root@localhost',
  $public_address         = '0.0.0.0',
  $server_name            = 'localhost',
  $public_port            = '443',
  $public_port_internal   = '5000',
  $admin_port             = '35357',
  $admin_port_internal    = '35357',
  $ssl                    = false,
  $cache_enabled          = false,
  $cache_config_prefix    = 'cache.keystone',
  $cache_expiration_time  = '600',
  $cache_backend          = undef,
  $cache_backend_argument = undef,
  $disable_db_sync        = false,
  $rewrites               = undef,
  $headers                = undef,
) {

  if $public_address == '0.0.0.0' {
    $address = '127.0.0.1'
  } else {
    $address = $public_address
  }

  include rjil::test::keystone

  Rjil::Test::Check {
    ssl     => $ssl,
    address => $address,
  }

  rjil::test::check { 'keystone':
    port => $public_port,
  }

  rjil::test::check { 'keystone-admin':
    port => $admin_port,
  }

  rjil::jiocloud::consul::service { "keystone":
    tags          => ['real'],
    port          => 5000,
  }

  rjil::jiocloud::consul::service { "keystone-admin":
    tags          => ['real'],
    port          => 35357,
  }

  # ensure that we don't even try to configure the
  # database connection until the service is up
  ensure_resource( 'rjil::service_blocker', 'mysql', {})
  Rjil::Service_blocker['mysql'] -> Keystone_config['database/connection']

  if $disable_db_sync {
    Exec <| title == 'keystone-manage db_sync' |> {
      unless => '/bin/true'
    }
  }

  include rjil::apache
  include ::keystone

  # these resources are here just until I ca refactor them out of the upstream
  # code
  Package<| title == 'keystone' |> {
    ensure => absent,
  }

  # switch to a custom provider that does nothing
  Service<| title == 'keystone' |> {
    provider => 'noop',
  }

  # not sure that I even want to do this, bringing down the whole
  # services container is a pain...
  Keystone_config<||> ~> Docker::Run['keystone']

  Docker::Run['keystone'] -> Keystone_user<||>
  Docker::Run['keystone'] -> Keystone_role<||>
  Docker::Run['keystone'] -> Keystone_tenant<||>
  Docker::Run['keystone'] -> Keystone_service<||>
  Docker::Run['keystone'] -> Keystone_endpoint<||>

  docker::run { 'keystone':
    image      => 'bodepd/keystone',
    detach     => true,
    # just for testing expose to differnet ports so that I can
    # run keystone next to the existing keystone
    ports      => ["${public_port_internal}:${public_port_internal}",
                   "${admin_port_internal}:${admin_port_internal}"],
    # attach entire etc volume
    volumes    => ['/etc/keystone/:/opt/keystone/conf'],
    dns        => [$::ipaddress_eth1],
    dns_search => ['node.consul', 'service.consul'],
  }

  ## Configure apache reverse proxy
  apache::vhost { 'keystone':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $public_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/keystone',
    error_log_file  => 'keystone.log',
    access_log_file => 'keystone.log',
    proxy_pass      => [ { path => '/', url => "http://localhost:${public_port_internal}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  ## Configure apache reverse proxy
  apache::vhost { 'keystone-admin':
    servername      => $server_name,
    serveradmin     => $admin_email,
    port            => $admin_port,
    ssl             => $ssl,
    docroot         => '/usr/lib/cgi-bin/keystone',
    error_log_file  => 'keystone.log',
    access_log_file => 'keystone.log',
    proxy_pass      => [ { path => '/', url => "http://localhost:${admin_port_internal}/"  } ],
    rewrites        => $rewrites,
    headers         => $headers,
  }

  ## Keystone cache configuration
  if $cache_enabled {
    keystone_config {
      'cache/enabled':          value => 'True';
      'cache/config_prefix':    value => $cache_config_prefix;
      'cache/expiration_time':  value => $cache_expiration_time;
      'cache/cache_backend':    value => $cache_backend;
      'cache/backend_argument': value => $cache_backend_argument;
    }
  }

  Class['rjil::keystone'] -> Rjil::Service_blocker<| title == 'keystone-admin' |>

  $keystone_logs = ['keystone-manage',
                    'keystone-all',
                    ]
  rjil::jiocloud::logrotate { $keystone_logs:
    logdir => '/var/log/keystone'
  }

}
