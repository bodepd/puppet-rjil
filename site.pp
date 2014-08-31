node base {
  # install users
  include rjil
  include rjil::jiocloud
  include rjil::jiocloud::sources
  include rjil::server
  realize (
    Rjil::Localuser['jenkins'],
    Rjil::Localuser['soren'],
  )
}

node /etcd/ inherits base {
  class { 'rjil::jiocloud::etcd':
    discovery => true,
    discovery_token => $::etcd_discovery_token
  }
}

node /apache/ inherits base {
  class { 'apache': }
}

node /openstackclient/ inherits base {
  class { 'openstack_extras::repo::uca':
    release => 'juno'
  }
  class { 'openstack_extras::client':
    ceilometer => false,
  }
}
