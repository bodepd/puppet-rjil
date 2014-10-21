class rjil::logforwarder(
  $cert,
  $servers     = ['127.0.0.1'],
  $server_port = '5000',
) {

  file { ['/etc/pki', '/etc/pki/certs', '/etc/pki/private']:
    ensure => directory,
  }

  file { '/etc/pki/certs/logstash-forwarder.crt':
    content => $cert,
  }

  file_line { 'syslog_add_pri':
    line => '$template  TraditionalWithPRI,"<%PRI%>%timegenerated% %HOSTNAME% %syslogtag%%msg%
$ActionFileDefaultTemplate TraditionalWithPRI',
    path => '/etc/rsyslog.conf',
    after => '$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat',
  } ~>
  service { 'rsyslog':
    ensure => running,
  }

  include '::logstashforwarder::repo'
  package { 'logstash-forwarder':
    ensure  => present,
    require => Class['logstashforwarder::repo'],
  }
  logstashforwarder_config { 'lsf-config':
    ensure => present,
    config => template('rjil/elk/forwarder_config.json.erb'),
    tag    => "LSF_CONFIG_${::fqdn}",
    path   => '/etc/logstash-forwarder',
  }
  logstashforwarder::file { 'syslog':
    paths  => ['/var/log/syslog'],
    fields => { 'type' => 'syslog'},
    notify => Service['logstash-forwarder'],
  }
  file { '/etc/init.d/logstashforwarder':
    content => template('logstashforwarder/etc/init.d/logstashforwarder.Debian.erb')
  }
  service { 'logstash-forwarder':
    ensure  => running,
    enable  => true,
    require => [
                 File['/etc/init.d/logstashforwarder'],
                 Logstashforwarder_config['lsf-config'],
               ]
  }
}
