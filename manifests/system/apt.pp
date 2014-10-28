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
  Apt::Source<||> -> Package<||>

  if $enable_puppetlabs {
    include puppet::repo::puppetlabs
  }

  if ($proxy) {
    file { '/etc/apt/apt.conf.d/90proxy':
      content => "Acquire::Http::Proxy \"${proxy}\";",
      owner => 'root',
      group => 'root',
      mode => '0644'
    }
  } else {
    file { '/etc/apt/apt.conf.d/90proxy':
      ensure => 'absent'
    }
  }
  create_resources(rjil::system::apt::repo, $repositories)
}
