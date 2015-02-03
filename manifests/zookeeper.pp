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
class rjil::zookeeper (
  $local_ip      = $::ipaddress,
  $hosts         = service_discover_consul('zookeeper.service.consul'),
  $leader_port   = 2888,
  $election_port = 3888,
  $leader        = false,
) {

  # for now, the id is hte last octet of the ip address, we may make it configurable later
  $zk_id = regsubst($local_ip, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')

  # both of these functions also have hardcoded the use of the 4th octet
  # to determine uniqueness
  $cluster_array     = generate_zookeeper_cluster_string($hosts, $leader_port, $election_port)
  $cluster_with_self = zookeeper_cluster_merge_self($cluster_array, $local_ip, $::hostname)

  if $leader {
    # tag ourselves as the cluster leader
    $service_tags = ['real', 'contrail', 'leader']
    # do we need to add deps?
  } else {
    $service_tags = ['real', 'contrail']
    # Block until leader address resolves (this ensures that we should
    # only fail at most once)
    ensure_resource('rjil::service_blocker', 'leader.zookeeper', {})
    Rjil::Service_blocker['leader.zookeeper'] -> File['/etc/zookeeper/conf/zoo.cfg']
    # if only our entry is in the cluster list
    if size($cluster_with_self) == 1 {
      notice()
      #
      # fail if our cluster list does not contain at least our entry + the leader
      # NOTE - should I be more strict about how I add the leader?
      runtime_fail {'zookeeper_list_empty':
        fail    => true,
        message => "Zookeeper list should contain at least 2 entries for non-leaders, only contained ${cluster_with_self}",
        before  => File['/etc/zookeeper/conf/zoo.cfg'],
        require => Rjil::Service_blocker['leader.zookeeper']
      }
    }
  }

  class { '::zookeeper':
    id      => $zk_id,
    servers => $cluster_with_self,
  }

  rjil::test { 'check_zookeeper.sh': }

  rjil::test::check { 'zookeeper':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 2181,
  }

  rjil::jiocloud::consul::service { 'zookeeper':
    port          => 2181,
    tags          => $service_tags,
  }

}
