define rjil::jiocloud::consul::service(
  $port          = 0,
  $check_command = "/usr/lib/jiocloud/tests/service_checks/${name}.sh",
  $interval      = '10s',
  $tags          = [],
  $ttl           = false,
) {

  $basic_hash = {
    name  => $name,
    port  => $port + 0,
    tags  => $tags,
  }

  if $check_command {
    $check_hash = {
      check => {
        script   => $check_command,
        interval => $interval
      }
    }
  } elsif $ttl {
    $check_hash = {
      check => {
        ttl => $ttl
      }
    }
  }

  $service_hash = {
    service => merge($basic_hash, $check_hash)
  }

  ensure_resource( 'file', '/etc/consul',
    {'ensure' => 'directory'}
  )

  file { "/etc/consul/$name.json":
    ensure => "present",
    content => template('rjil/consul.service.erb'),
  } ~> Exec <| title == 'reload-consul' |>
}
