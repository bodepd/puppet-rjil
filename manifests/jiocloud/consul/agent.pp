class rjil::jiocloud::consul::agent(
  $bind_addr = '0.0.0.0'
) {

  $ssl_dir   = '/home/consul/.puppet/ssl'
  $cert_name = "${hostname}.consul.cert"

  if ($::consul_discovery_token) {
    $join_address = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
  } else {
    fail('consul discovery token must be supplied')
  }

  rjil::puppet::cert { $cert_name:
    server  => $join_address,
  }

  class { 'rjil::jiocloud::consul':
    config_hash => {
      'bind_addr'        => $bind_addr,
      'start_join'       => [$join_address],
      'datacenter'       => "$::env",
      'data_dir'         => '/var/lib/consul-jio',
      'log_level'        => 'INFO',
      'server'           => false,
      'ca_file'          => "${ssl_dir}/certs/ca.pem",
      'cert_file'        => "${ssl_dir}/certs/${cert_name}.pem",
      'key_file'         => "${ssl_dir}/private_keys/${cert_name}.pem",
      'verify_incoming'  => true,
      'verify_outgoing'  => true,
    },
    require => Rjil::Puppet::Cert[$cert_name],
  }
}
