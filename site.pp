Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/","/usr/local/sbin/" ] }

node /etcd/ {
  include rjil::base

  if $::etcd_discovery_token {
    $discovery = true
  } else {
    $discovery = false
  }
  class { 'rjil::jiocloud::etcd':
    discovery       => $discovery,
    discovery_token => $::etcd_discovery_token
  }
}

node /openstackclient\d*/ {
  include rjil::base
  class { 'openstack_extras::repo::uca':
    release => 'juno'
  }
  class { 'openstack_extras::client':
    ceilometer => false,
  }
}

node /haproxy/ {
  include rjil::base
  include rjil::haproxy
  include rjil::haproxy::openstack
}

## Setup databases on db node
node /^db\d*/ {
  include rjil::base
  include rjil::db
}

## Setup memcache on mc node
node /mc\d*/ {
  include rjil::base
  include rjil::memcached
}

node /apache\d*/ {
  include rjil::base
  ## Configure apache reverse proxy
  include rjil::apache
  apache::vhost { 'nova-api':
    servername      => $::ipaddress_eth1,
    serveradmin     => 'root@localhost',
    port            => 80,
    ssl             => false,
    docroot         => '/var/www',
    error_log_file  => 'test.error.log',
    access_log_file => 'test.access.log',
    logroot         => '/var/log/httpd',
    #proxy_pass => [ { path => '/', url => "http://localhost:${nova_osapi_compute_listen_port}/"  } ],
  }

}

node /keystonewithdb\d+/ {
  include rjil::base
  include rjil::memcached
  include rjil::db
  include rjil::keystone
  # if I include these everywhere, it could lead to race conditions
  # for now, I am just going to include it on the keystone 'leader'
  include openstack_extras::keystone_endpoints
  include rjil::keystone::test_user
}

node /keystone\d+/ {
  include rjil::base
  include rjil::memcached
  include rjil::keystone
}
