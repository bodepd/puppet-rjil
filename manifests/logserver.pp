#
# Parameters:
# []
#
class rjil::logserver(
  $forwarder_key
) {

  include rjil::logforwarder

  class { '::logstash':
    manage_repo  => true,
    repo_version => '1.4',
    java_install => true
  }
  class { '::elasticsearch':
    manage_repo  => true,
    repo_version => '1.1',
    java_install => true
  }
  elasticsearch::instance { $::hostname: }
  include "::kibana3"
  file { '/etc/pki/private/logstash-forwarder.key':
    content => $forwarder_key,
  }

  logstash::configfile { 'lumberjack_input':
    content => template('rjil/elk/lumberjack_input.conf.erb'),
    order   => '01',
  }
  logstash::configfile { 'syslog_filter':
    content => template('rjil/elk/syslog_filter.conf.erb'),
    order   => '10',
  }
  logstash::configfile { 'lumberjack_output':
    content => template('rjil/elk/lumberjack_output.conf.erb'),
    order   => '30',
  }

}
