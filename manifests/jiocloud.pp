class rjil::jiocloud (
  $consul_role  = 'agent',
  $eat_data     = false,
  $forward_logs = false,
) {

  if ! member(['agent', 'server', 'bootstrapserver'], $consul_role) {
    fail("consul role should be agent|server|bootstrapserver, not ${consul_role}")
  }

  include rjil::system::apt

  if $consul_role == 'bootstrapserver' {
    include rjil::jiocloud::consul::cron
  } else {
    $addr = "${::consul_discovery_token}.service.consuldiscovery.linux2go.dk"
    dns_blocker {  $addr:
      try_sleep     => 5,
      tries         => 100,
      before    => Class["rjil::jiocloud::consul::${consul_role}"]
    }
  }
  include "rjil::jiocloud::consul::${consul_role}"

  if $forward_logs {
    include rjil::logforwarder
  }

  package { 'run-one':
    ensure => present,
  }

  file { '/usr/local/bin/jiocloud-update.sh':
    source => 'puppet:///modules/rjil/update.sh',
    mode => '0755',
    owner => 'root',
    group => 'root'
  }

  package { 'python-jiocloud': }

  if $eat_data {
    package { 'eatmydata':
      ensure => present,
      before => Cron['maybe-upgrade'],
    }
    $upgrade_command = 'run-one eatmydata /usr/local/bin/maybe-upgrade.sh'
  } else {
    $upgrade_command = 'run-one /usr/local/bin/maybe-upgrade.sh'
  }

  file { '/usr/local/bin/maybe-upgrade.sh':
    source => 'puppet:///modules/rjil/maybe-upgrade.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root'
  }
  cron { 'maybe-upgrade':
    command => $upgrade_command,
    user    => 'root',
    require => Package['run-one'],
  }

  ini_setting { 'templatedir':
    ensure  => absent,
    path    => "/etc/puppet/puppet.conf",
    section => 'main',
    setting => 'templatedir',
  }
}
