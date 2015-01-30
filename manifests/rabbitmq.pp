#
# Class: rjil::rabbitmq
#  This class to manage contrail rabbitmq dependency
#
# == Hiera elements required
#
# rabbitmq::manage_repo: no
#   This parameter to disable apt repo management in rabbitmq module
#
# rabbitmq::admin::enable: no
#   To disable rabbitmqadmin
#   Note: In original contrail installation it is disabled, so starting with
#   disabling it.
#


class rjil::rabbitmq {

  rjil::test { 'check_rabbitmq.sh': }

  include ::rabbitmq

  rjil::test::check { 'rabbitmq':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 5672,
  }

  rjil::jiocloud::consul::service { 'rabbitmq':
    tags          => ['real', 'contrail'],
    port          => 5672,
  }

}
