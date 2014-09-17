define rjil::profile {
  if ! defined(File['/var/lib/puppet/profile_list.txt']) {
    file { '/var/lib/puppet/profile_list.txt':
      ensure => file,
    }
  }
  file_line { "profile_${name}":
    path    => '/var/lib/puppet/profile_list.txt',
    line    => $name,
    require => File['/var/lib/puppet/profile_list.txt'],
  }
}
