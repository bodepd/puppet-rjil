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
) {

  if $override_ips {
    $identity_ips = $override_ips
  } else {
    $identity_ips = dns_resolve($identity_address)
  }

  if $identity_ips == '' {
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

  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_user<||> -> Anchor['after_keystone_obj']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_role<||> -> Anchor['after_keystone_obj']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_tenant<||> -> Anchor['after_keystone_obj']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_service<||> -> Anchor['after_keystone_obj']
  Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_endpoint<||> -> Anchor['after_keystone_obj']
  # the endpoints aren't usable until after the keystone objects exist
  Anchor['after_keystone_obj'] -> Rjil::Service_blocker['lb.glance']
  Anchor['after_keystone_obj'] -> Rjil::Service_blocker['lb.neutron']

  ensure_resource('rjil::service_blocker', 'lb.glance', {})
  ensure_resource('rjil::service_blocker', 'lb.neutron', {})

  # create a simple anchor so that we can have things block on all keystone objects
  anchor { 'after_keystone_obj':}

  Rjil::Service_blocker['lb.glance'] -> Glance_image<||>
  Rjil::Service_blocker['lb.neutron'] -> Neutron_network<||>

  # provision keystone objects for all services
  include openstack_extras::keystone_endpoints
  # provision tempest resources like images, network, users etc.
  include tempest::provision
  # create the user that performs validation tests
  include rjil::keystone::test_user

}
