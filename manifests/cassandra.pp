#
# Class: rjil::cassandra
#  This class to manage contrail cassandra dependency. Added parameters here to
#  set appropriate defaults, so that hiera config is not required unless any
#  extra configruation.
#
# == Hiera elements
#
# rjil::cassandra::seeds:
#   An array of all cassandra nodes
#
# rjil::cassandra::cluster_name:
#   Cassandra cluster name
# Default: 'contrail'
#
# rjil::cassandra::thread_stack_size:
#   JVM threadstack size for cassandra in KB.
#   Default value in cassandra module cause cassandra startup to fail, due to
#   low jvm thread stack size,
#   Default: 300
#
# rjil::cassandra::version:
#   Cassandra module doesnt support cassandra version 2.x. Also current contrail
#   implementation uses cassandra 1.2.x, so to provide version to avoid
#   installing latest package version which is 2.x
#
# rjil::cassandra::package_name:
#    Cassandra package name, the package name contains the major versions, so
#    have to set the package name.
#
# [*seed*] If we are the seed node used for bootstrapping
#

class rjil::cassandra (
  $local_ip          = $::ipaddress,
  $seeds             = values(service_discover_consul('cassandra', 'seed')),
  $seed              = false,
  $cluster_name      = 'contrail',
  $thread_stack_size = 300,
  $version           = '1.2.18-1',
  $package_name      = 'dsc12',
) {

  # if we are the seed, add ourselves to the list
  if $seed == true {
    $seeds_with_self = unique(concat($seeds, [$local_ip]))
  } else {
    if size($seeds) < 1 {
      $fail = true
      # this is just being set so that the cassandra class does not fail to compile
      $seeds_with_self = ['127.0.0.1']
    } else {
      $fail = false
      $seeds_with_self = $seeds
    }
  }

  rjil::seed_orchestrator { 'cassandra':
    port              => 9160,
    check_type        => 'tcp',
    tags              => ['real', 'contrail'],
    seed              => $seed,
    dep_resources     => File['/etc/cassandra/cassandra.yaml'],
    follower_fail     => $fail,
    follower_fail_msg => "Cassandra follower cannot be deployed without a seed, only contained ${cluster_with_self}"
  }

  rjil::test { 'check_cassandra.sh': }
  # make sure that hostname is resolvable or cassandra fails
  host { 'localhost':
    ip           => '127.0.0.1',
    host_aliases => ['localhost.localdomain', $::hostname],
  }

  if $thread_stack_size < 229 {
    fail("JVM Thread stack size (thread_stack_size) must be > 230")
  }

  class {'::cassandra':
    listen_address    => $local_ip,
    seeds             => $seeds_with_self,
    cluster_name      => $cluster_name,
    thread_stack_size => $thread_stack_size,
    version           => $version,
    package_name      => $package_name,
    require           => Host['localhost'],
  }

}
