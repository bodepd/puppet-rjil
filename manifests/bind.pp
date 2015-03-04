class rjil::bind(
  $bind_address = $ipaddress,
) {

  include ::bind

  rjil::test::check { 'dns':
    address => $bind_address,
    type    => 'dns',
    port    => 53,
  }

  rjil::jiocloud::consul::service { 'dns':
    tags          => ['real'],
    port          => 53,
  }

  # customize the bind config so that it doesn't bind to localhost
  file { '/etc/bind/named.conf.options':
    owner   => 'bind',
    group   => 'bind',
    content => template('rjil/bind/named.conf.options.erb'),
    notify  => Exec['reload bind9'],
  }
}
