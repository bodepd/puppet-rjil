class rjil::jiocloud::etcd(
  $addr = "${::ipaddress}:4001",
  $peer_addr = "${::ipaddress}:7001",
  $discovery = false,
  $discovery_token = '',
  $discovery_endpoint = 'https://discovery.etcd.io/',
) {
  class { '::etcd':
    addr               => $addr,
    bind_addr          => "0.0.0.0:4001",
    peer_addr          => $peer_addr,
    peer_bind_addr     => "0.0.0.0:7001",
    discovery          => $discovery,
    discovery_token    => $discovery_token,
    discovery_endpoint => $discovery_endpoint,
  } ->
  package { 'etcdctl':
    require => Exec['apt_update']
  }
  # for some reason, etcd requires an extra restart to come up sucessfully
  exec { '/bin/sleep 5; /usr/sbin/service etcd restart':
    refreshonly => true,
    subscribe   => Service['etcd'],
  }
}
