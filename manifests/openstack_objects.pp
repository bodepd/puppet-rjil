#
# This class is responsible for creating all objects in the openstack
# database.
#
# == Parameter
# [*identity_address*] Address used to resolve identity service.
#
class rjil::openstack_objects(
  $identity_address,
  $override_ips      = false,
  $magic_ip          = false,
) {

  if $override_ips {
    $identity_ips = $override_ips
  } else {
    $identity_ips = dns_resolve($identity_address)
  }

  $ip_array = split($identity_ips, ',')

  $ips_without_magic_ip = delete($ip_array, $magic_ip)

  if $ips_without_magic_ip == [] {
    $fail = true
  } else {
    $fail = false
  }
  # add a runtime fail and ensure that it blocks all object creation.
  # otherwise, it's possible that we might have to wait for network
  # timeouts if the dns address does not correctly resolve.
  runtime_fail {'keystone_endpoint_not_resolvable':
    fail => $fail
  }
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Class['openstack_extras::keystone_endpoints']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Class['keystone::endpoint']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Class['keystone::roles::admin']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Class['rjil::keystone::test_user']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Class['rjil::tempest::provision']

  # provision keystone objects for all services
  include openstack_extras::keystone_endpoints
  # provision tempest resources like images, network, users etc.
  include tempest::provision
  # create the user that performs validation tests
  include rjil::keystone::test_user

}
