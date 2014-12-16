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
  #
  # the usage of fake.cert as the positional argument is due to some issues I've
  # been having with this commands. Basically, --certname is first validated
  # to determine priveleges. If it does not exist, it is generated, then signed
  # and retrieved. When this occurs, the positional argument is generated, but
  # not retrieved.
  #
  exec { "${crt_command} ${name}.fake.cert --certname=${name} --server=${server}":
    user => $user,
    environment => ["HOME=${user_home}"],
    logoutput   => on_failure,
    creates     => "${user_home}/.puppet/ssl/certs/${name}.pem",
    require     => File[$user_home],
  }

}
