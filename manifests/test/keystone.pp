#
# Class: rjil::test::keystone
#
# Adds a validation scripts for keystone
#
#
class rjil::test::keystone {

  include openstack_extras::auth_file

  include rjil::test::base
  include ::keystone::client

  ensure_resource('package', 'python-keystoneclient')

  file { '/usr/lib/jiocloud/tests/keystone.sh':
    content => template('rjil/tests/keystone.sh.erb'),
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
