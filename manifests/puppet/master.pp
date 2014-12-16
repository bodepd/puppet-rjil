class rjil::puppet::master(
  $discovered_address = "",
) {

  Service['httpd'] -> Rjil::Puppet::Cert<||>

  class { "::puppet::master":
    autosign => true,
  }

  rjil::test::check { 'puppet-master':
    address => '127.0.0.1',
    port    => '8140',
    ssl     => true,
    type    => 'tcp',
  }

  rjil::jiocloud::consul::service { "puppet-master":
    tags          => ['real'],
    port          => 8140,
  }

}
