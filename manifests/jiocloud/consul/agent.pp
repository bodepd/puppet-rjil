class rjil::jiocloud::consul::agent(
  $bind_addr = '0.0.0.0'
) {

  if ($::consul_discovery_token) {
    $join_address = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
  } else {
    fail('consul discovery token must be supplied')
  }

  class { 'rjil::jiocloud::consul':
    override_hash => {
      'bind_addr'        => $bind_addr,
      'start_join'       => [$join_address],
    },
    ca_server     => $join_address,
  }
}
