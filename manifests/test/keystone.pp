#
# Class: rjil::test::keystone
#
class rjil::test::keystone(
  $api_address      = '127.0.0.1',
  $registry_address = '127.0.0.1',
  $ssl              = false,
) {

  include openstack_extras::auth_file

  include rjil::test::base

  ensure_resource('package', 'python-keystoneclient')

  file { "/usr/lib/jiocloud/tests/keystone.sh":
    content => template('rjil/tests/keystone.sh.erb'),
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
