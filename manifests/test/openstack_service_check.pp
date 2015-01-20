define rjil::test::openstack_service_check(
  $node_name = $::hostname,
) {

  $service   = split($name)[0]

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/openstack_service_check_${name}.sh":
    content => template('rjil/tests/openstack_service_check.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
