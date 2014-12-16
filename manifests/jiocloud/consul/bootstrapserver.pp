class rjil::jiocloud::consul::bootstrapserver(
  $bootstrap_expect = 1,
  $bind_addr        = '0.0.0.0',
  $ssl              = false,
) {

  if $ssl {
    include rjil::puppet::master
    Class['rjil::puppet::master'] -> Class['rjil::jiocloud::consul']
  }

  class { 'rjil::jiocloud::consul':
    override_hash => {
      'bind_addr'        => $bind_addr,
      'server'           => true,
      'bootstrap_expect' => $bootstrap_expect + 0,
    },
    ssl => $ssl,
  }
}
