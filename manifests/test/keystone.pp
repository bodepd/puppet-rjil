class rjil::test::keystone(
  $admin_address  = '127.0.0.1',
  $public_address = '127.0.0.1',
){

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/keystone.sh":
    content => template('rjil/tests/keystone.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '755',
  }

}
