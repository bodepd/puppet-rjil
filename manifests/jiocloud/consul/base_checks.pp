class rjil::jiocloud::consul::base_checks(
  # default to 5 days
  $puppet_ttl       = '7200m',
  $validation_ttl   = '7200m',
  $puppet_notes     = 'Status of Puppet run',
  $validation_notes = 'Status of configuration validation checks'
) {

  consul::check { 'puppet':
    ttl   => $puppet_ttl,
    notes => $puppet_notes,
  }

  consul::check { 'validation':
    ttl   => $validation_ttl,
    notes => $validation_notes,
  }

}
