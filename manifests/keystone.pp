#
# profile for configuring keystone role
#
class rjil::keystone(
  $admin_email            = 'root@localhost',
  $public_address         = '0.0.0.0',
  $public_port            = '443',
  $public_port_internal   = '5000',
  $admin_port             = '35357',
  $admin_port_internal    = '35357',
  $ssl                    = false,
  $ceph_radosgw_enabled   = false,
  $cache_enabled          = false,
  $cache_config_prefix    = 'cache.keystone',
  $cache_expiration_time  = '600',
  $cache_backend          = undef,
  $cache_backend_argument = undef,
) {

  include rjil::test::keystone

  if $ssl {
    include rjil::apache
  }

  class { '::keystone': }
  include openstack_extras::keystone_endpoints
  # class { 'keystone::cron::token_flush': }

  if $ceph_radosgw_enabled {
    include rjil::keystone::radosgw
  }

  if $ssl {
    ## Configure apache reverse proxy
    apache::vhost { 'keystone':
      servername      => $public_address,
      serveradmin     => $admin_email,
      port            => $public_port,
      ssl             => $ssl,
      docroot         => '/usr/lib/cgi-bin/keystone',
      error_log_file  => 'keystone.log',
      access_log_file => 'keystone.log',
      proxy_pass      => [ { path => '/', url => "http://localhost:${public_port_internal}/"  } ],
    }

    ## Configure apache reverse proxy
    apache::vhost { 'keystone-admin':
      servername      => $public_address,
      serveradmin     => $admin_email,
      port            => $admin_port,
      ssl             => $ssl,
      docroot         => '/usr/lib/cgi-bin/keystone',
      error_log_file  => 'keystone.log',
      access_log_file => 'keystone.log',
      proxy_pass      => [ { path => '/', url => "http://localhost:${admin_port_internal}/"  } ],
    }
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

}
