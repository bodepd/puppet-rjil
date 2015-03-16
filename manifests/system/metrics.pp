#
# == Parameters
# [disks] disks that we should set thresholds for
# [disk_percent_warn] Disk utilization percentage that should be treated
# as a warning.
# [disk_percent_fail] Disk utilization percentage that should be treated
# as a failure
# [notification_type] Type used to write notifications. Currnetly only supports
# log.
#
class rjil::system::metrics(
  $disks = ['root'],
  $disk_percent_warn = '10',
  $disk_percent_fail = '5',
  $notification_type = 'log',
  $log_file          = '/usr/lib/jiocloud/metrics/collectd_notifications.log',
) {

  user { 'alert-user':
    ensure => present,
  }

  # remove all default plugins so that we can fully customize
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }

  # write data to csv files
  file { ['/var/lib/metrics', '/var/lib/metrics/collectd', '/var/lib/metrics/collectd/csv']:
    ensure => directory,
  }

  class { 'collectd::plugin::csv':
    datadir    => '/var/lib/metrics/collectd/csv',
    storerates => false,
  }

  # config for thresholds
  file { '/etc/collectd/conf.d/20-thresholds.conf':
    content => template('rjil/collectd/thresholds.conf.erb'),
    notify => Service['collectd'],
  }

  file { '/etc/collectd/conf.d/20-notifications.conf':
    content => template("rjil/collectd/${notification_type}_notifications.conf.erb"),
    notify  => Service['collectd'],
    require => File['/usr/lib/jiocloud/metrics'],
  }

  include collectd::plugin::memory

  class { 'collectd::plugin::df':
    valuespercentage => true
  }

  # keep track of the number of users logged into the system
  #include collectd::plugin::users

  #include collectd::plugin::conntrack

  # keep cpu stats
  #include collectd::plugin::cpu

  # monitor VMs
  #class { 'collectd::plugin::libvirt':
  #  connection       => 'qemu:///system',
  #  interface_format => 'address'
  #}
  #include collectd::plugin::disk

  #include collectd::plugin::ntpd

  # I would like to include ping, but I don't know what to ping...

  # data that I want to collect that does not exist in the puppet module
  # this does not exist in the module...
  # include collectd::plugin::dns
  # I would like data on ethstat
  # libvirt, vserver

  # register a consul service that we can use to send out alerts to
  rjil::jiocloud::consul::service { 'metric_thresholds':
    interval     => '120s',
    tags          => ['metrics'],
    check_command => '/usr/lib/jiocloud/metrics/check_thresholds.sh',
  }

  file { '/usr/lib/jiocloud/metrics':
    ensure => directory,
  }
  file { '/usr/lib/jiocloud/metrics/check_thresholds.sh':
    mode    => '0755',
    content => template('rjil/tests/check_thresholds.sh.erb')
  }
  file { '/usr/lib/jiocloud/metrics/check_thresholds.py':
    mode    => '0755',
    source => 'puppet:///modules/rjil/tests/check_thresholds.py'
  }

}
