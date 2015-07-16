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
  $users             = {},
  $tenants           = undef,
  $roles             = undef,
  $lb_available      = true,
  $keystone_enabled  = true,
  $glance_enabled    = true,
  $neutron_enabled   = true,
  $tempest_enabled   = true,
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

  ##
  # LB may not be available all the time, so make it optional - e.g, lb may not
  # be available in case of undercloud
  ##
  if $lb_available {
    $glance_service_name  = 'lb.glance'
    $neutron_service_name = 'lb.neutron'
  } else {
    $glance_service_name  = 'glance'
    $neutron_service_name = 'neutron'
  }

  # add a runtime fail and ensure that it blocks all object creation.
  # otherwise, it's possible that we might have to wait for network
  # timeouts if the dns address does not correctly resolve.
  runtime_fail {'keystone_endpoint_not_resolvable':
    fail => $fail
  }

  if $keystone_enabled {
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_user<||>
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_role<||>
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_tenant<||>
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_service<||>
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Keystone_endpoint<||>
    # provision keystone objects for all services
    include openstack_extras::keystone_endpoints
    # provision tempest resources like images, network, users etc.
    create_resources('rjil::keystone::user',$users)

    ##
    # Tenants can be created without creating users, $tenants can be an array of
    # all tenant names to be created, and a hash of tenants with appropriate
    # params for rjil::keystone::tenant
    ##
    if is_array($tenants) {
      rjil::keystone::tenant { $tenants: }
    } elsif is_hash($tenants) {
      create_resources('rjil::keystone::tenants',$tenants)
    }
  }
  if $glance_enabled {
    ensure_resource('rjil::service_blocker', $glance_service_name, {})
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Rjil::Service_blocker[$glance_service_name]
    Rjil::Service_blocker[$glance_service_name] -> Glance_image<||>
    include ::archive
    archive { '/usr/lib/jiocloud/cirros-0.3.3-x86_64-disk.img':
      source   => 'http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img',
      before   => Glance_image['cirros-0.3.3'],
    }
    # create users, tenants, roles, default networks
  }
  if $neutron_enabled {
    ensure_resource('rjil::service_blocker', $neutron_service_name, {})
    Runtime_fail['keystone_endpoint_not_resolvable'] -> Rjil::Service_blocker[$neutron_service_name]
    Rjil::Service_blocker[$neutron_service_name] -> Neutron_network<||>
  }
  if $tempest_enabled {
    include tempest::provision
  }

  if is_array($roles) {
    keystone_role { $roles:
      ensure => present,
    }
  } elsif is_hash($roles) {
    create_resources('keystone_role',$roles,{ensure =>present})
  }
}
