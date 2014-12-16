class rjil::jiocloud::consul(
  $override_hash       = {},
  $ssl                 = false,
  $ca_server           = 'localhost',
  $ssl_dir             = '/home/consul/.puppet/ssl',
  $cert_name           = "${hostname}.consul.cert",
  $disable_remote_exec = true,
  $encrypt             = false,
) {

  $defaults_hash = {
    'datacenter'          => $::consul_discovery_token,
    'data_dir'            => '/var/lib/consul-jio',
    'log_level'           => 'INFO',
    'enable_syslog'       => true,
    'server'              => false,
    'disable_remote_exec' => $disable_remote_exec,
  }

  #
  # Add ssl specific options if we are setting ssl
  #
  if $ssl {
    $ssl_hash = {
      'ca_file'         => "${ssl_dir}/certs/ca.pem",
      'cert_file'       => "${ssl_dir}/certs/${cert_name}.pem",
      'key_file'        => "${ssl_dir}/private_keys/${cert_name}.pem",
      'verify_incoming' => true,
      'verify_outgoing' => true,
    }
    rjil::puppet::cert { $cert_name:
      server => $ca_server,
      before => Service['consul'],
    }
  } else {
    $ssl_hash = {}
  }

  if $encrypt {
    $encrypt_hash = {'encrypt' => $encrypt}
  } else {
    $encrypt_hash = {}
  }

  $config_hash = merge($defaults_hash, $ssl_hash, $encrypt_hash, $override_hash)

  include dnsmasq

  dnsmasq::conf { 'consul':
    ensure  => present,
    content => 'server=/consul/127.0.0.1#8600',
  }

  class { '::consul':
    install_method    => 'package',
    ui_package_name   => 'consul-web-ui',
    ui_package_ensure => 'absent',
    bin_dir           => '/usr/bin',
    config_hash       => $config_hash,
  }
  exec { "reload-consul":
    command     => "/usr/bin/consul reload",
    refreshonly => true,
    subscribe   => Service['consul'],
  }

}
