#
# Class: rjil::test::neutron
#   Adding tests for neutron services
#

class rjil::test::neutron(
  $net_number = $::hostname,
) {

  include openstack_extras::auth_file

  include rjil::test::base

  file { '/usr/lib/jiocloud/tests/neutron-service.sh':
    content => template('rjil/tests/neutron.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/usr/lib/jiocloud/tests/floating_ip.sh':
    source => 'puppet:///modules/rjil/tests/floating_ip.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
