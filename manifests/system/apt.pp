## Class rjil::system::apt
## Purpose: configure apt sources
class rjil::system::apt (
  $enable_puppetlabs = true,
  $proxy             = false,
  $repositories      = {},
) {

  ## two settings to be overrided here in hiera
  ## apt::purge_sources_list: true, apt::purge_sources_list_d: true
  include ::apt

  ## All package operations should follow apt::source
  Apt::Source<||> {
    tag => 'package',
  }
  Apt::Pin<||> {
    tag => 'package',
  }
  Apt::Source<||> -> Package<||>
  Apt::Pin<||> -> Package<||>
  File['/etc/apt/preferences.d/ignore_rusted_halo_openstack'] -> Package<||>

  if $enable_puppetlabs {
    include puppet::repo::puppetlabs
  }

  file { '/etc/apt/preferences.d/ignore_rusted_halo_openstack':
    content =>
'Package:  *
Pin: release o=JioCloud
Pin-Priority: 1',
    tag   => 'package',
  }

  if ($proxy) {
    file { '/etc/apt/apt.conf.d/90proxy':
      content => "Acquire::Http::Proxy \"${proxy}\";",
      owner => 'root',
      group => 'root',
      mode  => '0644',
      tag   => 'package',
    }
  } else {
    file { '/etc/apt/apt.conf.d/90proxy':
      ensure => 'absent',
      tag   => 'package',
    }
  }
  create_resources(apt::source, $repositories, {'tag' => 'package'} )
}
