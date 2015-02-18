###
## Class: rjil::contrail
###
class rjil::contrail::server () {

  # put more dependencies between contrail and things that
  # it depends on. Contrail services seem to get stuck in
  # bad states and I have a feeling that it is because certain
  # type of connection failures are not recoverable
  #
  anchor{'contrail_dep_apps':}
  Service<| title == 'zookeeper' |>       ~> Anchor['contrail_dep_apps']
  Service<| title == 'cassandra' |>       ~> Anchor['contrail_dep_apps']
  Service<| title == 'rabbitmq-server' |> ~> Anchor['contrail_dep_apps']

  Anchor['contrail_dep_apps'] -> Service['contrail-api']
  Anchor['contrail_dep_apps'] -> Service['contrail-schema']
  Anchor['contrail_dep_apps'] -> Service['contrail-analytics-api']
  Anchor['contrail_dep_apps'] -> Service['contrail-collector']
  Anchor['contrail_dep_apps'] -> Service['contrail-query-engine']
  Anchor['contrail_dep_apps'] -> Service['contrail-svc-monitor']
  Anchor['contrail_dep_apps'] -> Service['contrail-discovery']
  Anchor['contrail_dep_apps'] -> Service['contrail-dns']
  Anchor['contrail_dep_apps'] -> Service['contrail-control']
  Anchor['contrail_dep_apps'] -> Service['ifmap-server']

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
