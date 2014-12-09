class rjil::http_proxy() {

  class { 'squid3':
    cache_dir => ['ufs /var/spool/squid3 10000 16 256'],
    # allow objects up to 500MB
    maximum_object_size           => '50096 KB',
    # allow objects in memory up to 5M
    maximum_object_size_in_memory => '5012 KB',
  }

  Service<| title == 'squid3_service' |> {
    provider => 'upstart',
    enable   => undef,
  }

  rjil::jiocloud::consul::service {'proxy':
    port          => '3128',
    tags          => ['real'],
    check_command => "/usr/lib/nagios/plugins/check_http -H localhost -p 3128",
  }

}

