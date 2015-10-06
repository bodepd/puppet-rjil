#
# This has been shamelessly lifed from stacktira
#
# This is essentially the profile for haproxy
#
#
class rjil::haproxy (
  $consul_service_tags     = [],
  $logfile                 = '/var/log/haproxy.log',
  $log_level               = '127.0.0.1 local0 notice',
  $default_log_level       = 'global',
  $default_mode            = 'http',
  $default_options         = ['httplog', 'dontlognull', 'redispatch'],
  $default_retries         = 3,
  $default_maxconn         = 5000,
  $default_timeout_connect = 20000,
  $default_timeout_client  = 20000,
  $default_timeout_server  = 20000,
  $errorfile               = [
                              '400 /etc/haproxy/errors/400.http',
                              '403 /etc/haproxy/errors/403.http',
                              '408 /etc/haproxy/errors/408.http',
                              '500 /etc/haproxy/errors/500.http',
                              '502 /etc/haproxy/errors/502.http',
                              '503 /etc/haproxy/errors/503.http',
                              '504 /etc/haproxy/errors/504.http'
                            ],
  $global_maxconn          = 5000,
  $stats                   = 'socket /var/run/haproxy mode 777',
  $consul_wait             = '5s:30s',
  $consul_log_level        = 'debug',
) {

  rjil::test { 'haproxy.sh': }

  $haproxy_defaults = {
    'log'        => $default_log_level,
    'mode'       => $default_mode,
    'option'     => $default_options,
    'retries'    => $default_retries,
    'maxconn'    => $default_maxconn,
    'timeout'    => [ "connect ${default_timeout_connect}",
                      "client ${default_timeout_client}",
                      "server ${default_timeout_server}" ],
    'errorfile'  => $errorfile,
  }

  $haproxy_globals = {
    'log'       => $log_level,
    'maxconn'   => $global_maxconn,
    'user'      => 'haproxy',
    'group'     => 'haproxy',
    'daemon'    => '',
    'quiet'     => '',
    'stats'     => $stats,
  }


  # TODO - add all services for openstack here, and get rid of the
  # haproxy/openstack and haproxy_service classes

  rjil::jiocloud::logrotate { 'haproxy': }

  #
  # commented out configuration related to keepalive d
  # for multiple lbs
  #

  haproxy::listen { 'lb-stats':
    ipaddress => '0.0.0.0',
    ports     => '8094',
    mode      => 'http',
    options   => {
      'option'  => [
        'httplog',
      ],
      'stats' => ['enable', 'uri /lb-stats'],
    },
    collect_exported => false,
  }

  package { ['nagios-plugins-contrib', 'libwww-perl', 'libnagios-plugin-perl']:
    ensure => 'present'
  }

  rjil::jiocloud::consul::service { "haproxy":
    port          => 8094,
    check_command => "/usr/lib/nagios/plugins/check_haproxy -u 'http://0.0.0.0:8094/lb-stats;csv'",
    tags          => $consul_service_tags
  }

  class { 'consul_template':
    init_style     => 'upstart',
    log_level      => $consul_log_level,
    consul_wait    => $consul_wait,
  }

  class { '::haproxy':
    global_options   => $haproxy_globals,
    defaults_options => $haproxy_defaults,
    config_file      => "${consul_template::config_dir}/haproxy.ctmpl",
  }

  Service['consul-template'] -> Service['haproxy']

  consul_template::watch { 'haproxy':
    destination   => '/etc/haproxy/haproxy.cfg',
    command       => '/etc/init.d/haproxy reload',
  }

}
