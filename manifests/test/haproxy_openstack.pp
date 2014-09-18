class rjil::test::haproxy_openstack(
  $horizon_ips           = [],
  $keystone_ips          = [],
  $keystone_internal_ips = [],
  $glance_ips            = [],
  $cinder_ips            = [],
  $nova_ips              = [],
) {

  include openstack_extras::auth_file

  include rjil::test::base

  if ($keystone_ips != [] or $keystone_internal_ips != []) {
    include keystone::client
  }

  file { "/usr/lib/jiocloud/tests/haproxy_openstack.sh":
    content => template('rjil/tests/haproxy_openstack.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '755',
  }

}
