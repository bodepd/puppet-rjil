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
  $hosts         = service_discover_consul('pre-zookeeper'),
  $leader_port   = 2888,
  $election_port = 3888,
  $seed          = false,
  $min_members   = 3,
  $datastore     = '/var/lib/zookeeper'
) {

  # for now, the id is the last octet of the ip address, we may make it configurable later
  $zk_id = regsubst($local_ip, '^(\d+)\.(\d+)\.(\d+)\.(\d+)$','\4')

  # both of these functions also have hardcoded the use of the 4th octet
  # to determine uniqueness
  $cluster_array     = generate_zookeeper_cluster_string($hosts, $leader_port, $election_port)
  $cluster_with_self = zookeeper_cluster_merge_self($cluster_array, $local_ip, $::hostname)

  # forward non-seed failures when there is no leader in their cluster list
  if size($cluster_with_self) < $min_members {
    $fail = true
  } else {
    $fail = false
  }

  $zk_cfg    = '/etc/zookeeper/conf'
  $zk_files = File["${zk_cfg}/zoo.cfg", "${zk_cfg}/environment", "${zk_cfg}/log4j.properties", "${zk_cfg}/myid"]

  runtime_fail { 'zk_members_not_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} zk members",
    before  => $zk_files,
  }

  # Add a check that always succeeds that we can use to know
  # when we have enough members ready to configure a cluster.
  rjil::jiocloud::consul::service { 'pre-zookeeper':
    check_command => '/bin/true'
  }

  # the non-seed nodes should not configure themselves until
  # there is at least one active seed node
  if ! $seed {
    rjil::service_blocker { "zookeeper":
      before  => $zk_files,
      require => Runtime_fail['zk_members_not_ready']
    }
  }

  rjil::test::check { 'zookeeper':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 2181,
  }

  rjil::jiocloud::consul::service { 'zookeeper':
    port          => 2181,
    tags          => ['real', 'contrail'],
  }

  class { '::zookeeper':
    id        => $zk_id,
    servers   => $cluster_with_self,
    datastore => $datastore,
  }

  file { "${datastore}/myid":
    ensure => link,
    target => "${zk_cfg}/myid",
    notify => Service['zookeeper'],
  }


  rjil::test { 'check_zookeeper.sh': }

}
