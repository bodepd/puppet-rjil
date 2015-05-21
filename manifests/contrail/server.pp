###
## Class: rjil::contrail
###
class rjil::contrail::server (
  $enable_analytics = true,
  $zk_ip_list        = sort(values(service_discover_consul('zookeeper'))),
  $cassandra_ip_list = sort(values(service_discover_consul('cassandra'))),
  $config_ip_list    = sort(values(service_discover_consul('contrail', 'real'))),
  $min_members       = 3,
) {

  # Do not initialize contrail services until the entire data plane has been
  # correctly scaled and configured. This is intended to prevent any issues
  # where scaling the data sources causes inconsistencies with data initializations
  # in contrail
  if size($zk_ip_list) < $min_members or size($cassandra_ip_list) < $min_members {
    $fail = true
  } else {
    $fail = false
  }
  runtime_fail { 'contrail_data_not_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} zk and cassandra for contrail",
    before  => Anchor['contrail_dep_apps'],
  }

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
  Anchor['contrail_dep_apps'] -> Service['contrail-discovery']
  Anchor['contrail_dep_apps'] -> Service['contrail-dns']
  Anchor['contrail_dep_apps'] -> Service['contrail-control']
  Anchor['contrail_dep_apps'] -> Service['ifmap-server']

  ##
  # Added tests
  ##
  $contrail_tests = ['ifmap.sh','contrail-api.sh',
                      'contrail-control.sh','contrail-discovery.sh',
                      'contrail-dns.sh',
                      'contrail-webui-webserver.sh','contrail-webui-jobserver.sh']

  rjil::test {$contrail_tests:}

  if $enable_analytics {
    rjil::test {'contrail-analytics.sh':}
  }

  $contrail_logs = [  'contrail-analytic-api',
                      'contrail-collector',
                      'query-engine',
                      'api',
                      'discovery',
                      'schema',
                      'svc-monitor',
                      'contrail-control',
                      'webserver',
                      'jobserver',
  ]
  rjil::jiocloud::logrotate { $contrail_logs:
    logdir => '/var/log/contrail'
  }

  file { '/usr/lib/jiocloud/tests/contrail-schema.sh':
    content => template('rjil/tests/contrail-schema.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '755',
  }

  class { '::contrail':
    zk_ip_list        => $zk_ip_list,
    cassandra_ip_list => $cassandra_ip_list
  }

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
