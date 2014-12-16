class rjil::jiocloud::consul::server(
  $bind_addr = '0.0.0.0'
){
  if ($::consul_discovery_token) {
    $join_address = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
  } else {
    $join_address = ''
  }

  class { 'rjil::jiocloud::consul':
    override_hash => {
      'bind_addr'        => $bind_addr,
      'start_join'       => [$join_address],
      'server'           => true,
    },
    ca_server => $join_address,
  }
}
