#
# Class: rjil::redis
#  This class to manage contrail redis dependency
#
#

class rjil::redis {

  rjil::test { 'check_redis.sh': }

  include ::redis

  rjil::test::check { 'redis':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 6379,
  }

  rjil::jiocloud::consul::service { 'redis':
    tags          => ['real', 'contrail'],
    port          => 6379,
  }


}
