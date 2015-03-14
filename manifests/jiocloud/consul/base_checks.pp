class rjil::jiocloud::consul::base_checks(
  # assumes puppet should run at least once a day
  $puppet_ttl       = '1440m',
  # assumes that validation should run at least once an hour
  $validation_ttl   = '60m',
  $puppet_notes     = 'Status of Puppet run',
  $validation_notes = 'Status of configuration validation checks'
) {

  rjil::jiocloud::consul::service { 'puppet':
    check_command => false,
  }

  consul::check { 'puppet':
    ttl        => $puppet_ttl,
    notes      => $puppet_notes,
    service_id => 'puppet',
    require    => Rjil::Jiocloud::Consul::Service['puppet'],
  }

  rjil::jiocloud::consul::service { 'validation':
    check_command => false,
  }

  consul::check { 'validation':
    ttl        => $validation_ttl,
    notes      => $validation_notes,
    service_id => 'validation',
    require    => Rjil::Jiocloud::Consul::Service['validation'],
  }

}
