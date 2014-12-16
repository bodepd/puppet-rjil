#
# generate a puppet cert that will be used by consul
#
define rjil::puppet::cert(
  $server,
  $user = 'consul',
) {

  $user_home="/home/$user"

  file { $user_home:
    ensure => directory,
    owner  => 'consul',
    group  => 'consul',
  }

  $crt_command = "/usr/bin/puppet certificate generate --ca-location=remote"
  exec { "${crt_command} ${name} --certname ${name} --server=${server}":
    user => $user,
    environment => ["HOME=${user_home}"],
    logoutput   => on_failure,
    creates     => "${user_home}/.puppet/ssl/certs/${name}.pem",
    require     => File[$user_home],
  }

}
