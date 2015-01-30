###
## Class: rjil::contrail
###
class rjil::contrail::server () {

  ##
  # Added tests
  ##
  $contrail_tests = ['ifmap.sh','contrail-analytics.sh','contrail-api.sh',
                      'contrail-control.sh','contrail-discovery.sh',
                      'contrail-dns.sh','contrail-schema.sh',
                      'contrail-webui-webserver.sh','contrail-webui-jobserver.sh']
  rjil::test {$contrail_tests:}

  include ::contrail

  rjil::test::check { 'contrail':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 9160,
  }

  rjil::jiocloud::consul::service { 'contrail':
    tags          => ['real', 'contrail'],
    port          => 9160,
  }

}
