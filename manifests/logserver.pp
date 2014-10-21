#
# Parameters:
# []
#
class rjil::logserver(
  $forwarder_key
) {

  Service['logstash'] -> Service['logstash-forwarder']
  include "::kibana3"
  include rjil::logforwarder
  class { '::elasticsearch':
    manage_repo  => true,
    repo_version => '1.1',
    java_install => true
  }
  elasticsearch::instance { $::hostname: }
  class { '::logstash':
    manage_repo  => true,
    repo_version => '1.4',
    java_install => true,
  }
  file { '/etc/pki/private/logstash-forwarder.key':
    content => $forwarder_key,
  }

  logstash::configfile { 'lumberjack_input':
    content => template('rjil/elk/lumberjack_input.conf.erb'),
    order   => '01',
    require => File['/etc/pki/private/logstash-forwarder.key'],
  }
  logstash::configfile { 'syslog_filter':
    content => template('rjil/elk/syslog_filter.conf.erb'),
    order   => '10',
  }
  logstash::configfile { 'lumberjack_output':
    content => template('rjil/elk/lumberjack_output.conf.erb'),
    order   => '30',
  }

  rjil::test { 'logserver.sh': }

  rjil::jiocloud::consul::service { "logserver":
    tags          => ['real'],
    port          => 5000,
    check_command => '/usr/lib/jiocloud/tests/logserver.sh',
  }

}
