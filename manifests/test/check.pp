#
# Class: rjil::test::cinder
#   Adding tests for cinder services
#

define rjil::test::check(
  $port    = 0,
  $address = '127.0.0.1',
  $ssl     = false,
  $type    = 'http',
) {

  include rjil::test::base

  file { "/usr/lib/jiocloud/tests/service_checks/${name}.sh":
    content => template("rjil/tests/${type}_check.sh.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

}
