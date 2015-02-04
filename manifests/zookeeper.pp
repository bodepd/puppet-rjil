#
# Class: rjil::zookeeper
#  This class to manage contrail zookeeper dependency
#
# == Parameters
#
# [*local_ip*]
#   The ip address of a host that should be used to register it to
#   a cluster. Defaults to $::ipaddress
#
# [*hosts*]
#    Hash of host => ip for all zookeeper hosts. Defaults to all hosts
#    with the zookeeper service in consul.
#
# [*leader_port*]
#    Port that instances use to connect to a leader.
#
# [*election_port*]
#    Port used for leader elections.
#
# [*seed*]
#    If we are the seed nood used for bootstrapping
#
class rjil::zookeeper (
  $local_ip      = $::ipaddress,
  $hosts         = service_discover_consul('zookeeper'),
  $leader_port   = 2888,
  $election_port = 3888,
  $seed        = false,
) {

  # for now, the id is the last octet of the ip address, we may make it configurable later
  $zk_id = regsubst($local_ip, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')

  # both of these functions also have hardcoded the use of the 4th octet
  # to determine uniqueness
  $cluster_array     = generate_zookeeper_cluster_string($hosts, $leader_port, $election_port)
  $cluster_with_self = zookeeper_cluster_merge_self($cluster_array, $local_ip, $::hostname)

  # forward non-seed failures when there is no leader in their cluster list
  if size($cluster_with_self) == 1 {
    $fail = true
  } else {
    $fail = false
  }

  rjil::seed_orchestrator { 'zookeeper':
    port              => 2181,
    check_type        => 'tcp',
    tags              => ['real', 'contrail'],
    seed              => $seed,
    dep_resources     => File['/etc/zookeeper/conf/zoo.cfg'],
    follower_fail     => $fail,
    follower_fail_msg => "Zookeeper follower cannot be deployed without a leader, only contained ${cluster_with_self}"
  }

  class { '::zookeeper':
    id      => $zk_id,
    servers => $cluster_with_self,
  }

  rjil::test { 'check_zookeeper.sh': }

}
