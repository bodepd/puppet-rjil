###
## Class: rjil::contrail
###
class rjil::contrail::server () {

  # put more dependencies between contrail and things that
  # it depends on. Contrail services seem to get stuck in
  # bad states and I have a feeling that it is because certain
  # type of connection failures are not recoverable
  #
  Service<| title == 'zookeeper' |>        ~> Anchor['contrail::end_base_services']
  Service<| title == 'cassandra' |>        ~> Anchor['contrail::end_base_services']
  Service<| title == 'rabbitmq-server' |>  ~> Anchor['contrail::end_base_services']

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
