define rjil::jiocloud::consul::service(
  $port          = 0,
  $check_command = "/usr/lib/jiocloud/tests/service_checks/${name}.sh",
  $interval      = '10s',
  $tags          = [],
) {
  $default_hash = {
    service => {
      name  => $name,
      port  => $port + 0,
      tags  => $tags,
    }
  }

  if $check_command {
    $check_hash = {
      check => {
        script => $check_command,
        interval => $interval
      }
    }
  } else {
    $check_hash = {}
  }

  $service_hash_inner = merge($default_hash['service'], $check_hash)
  $service_hash       = {service => $service_hash_inner}

  ensure_resource( 'file', '/etc/consul',
    {'ensure' => 'directory'}
  )

  file { "/etc/consul/$name.json":
    ensure => "present",
    content => template('rjil/consul.service.erb'),
  } ~> Exec <| title == 'reload-consul' |>
}
