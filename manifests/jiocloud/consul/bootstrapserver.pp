class rjil::jiocloud::consul::bootstrapserver(
  $bootstrap_expect = 1,
  $bind_addr        = '0.0.0.0',
) {

  $ssl_dir   = '/home/consul/.puppet/ssl'
  $cert_name = "${hostname}.consul.cert"

  include rjil::puppet::master

  rjil::puppet::cert { $cert_name:
    server  => 'localhost',
    require => Class['::puppet::master'],
  }

  class { 'rjil::jiocloud::consul':
    config_hash => {
      'bind_addr'        => $bind_addr,
      'datacenter'       => $::env,
      'data_dir'         => '/var/lib/consul-jio',
      'log_level'        => 'INFO',
      'server'           => true,
      'bootstrap_expect' => $bootstrap_expect + 0,
      'ca_file'          => "${ssl_dir}/certs/ca.pem",
      'cert_file'        => "${ssl_dir}/certs/${cert_name}.pem",
      'key_file'         => "${ssl_dir}/private_keys/${cert_name}.pem",
      'verify_incoming'  => true,
      'verify_outgoing'  => true,
    },
    require => Rjil::Puppet::Cert[$cert_name],
  }
}
