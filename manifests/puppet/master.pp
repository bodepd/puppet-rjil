class rjil::puppet::master(
  $discovered_address = "",
) {

  Service['httpd'] -> Rjil::Puppet::Cert<||>

  class { "::puppet::master":
    autosign => true,
  }

  rjil::jiocloud::consul::service { "puppet-master":
    tags          => ['real'],
    port          => 8140,
    check_command => "/usr/lib/nagios/plugins/check_http -I 127.0.0.1 -p 8140"
  }

}
