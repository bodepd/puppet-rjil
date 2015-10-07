#
# Class: rjil::haproxy::openstack
#   Setup openstack services in haproxy.
#
class rjil::haproxy::openstack(
  $horizon_ips           = sort(values(service_discover_consul('horizon', 'real'))),
  $keystone_ips          = sort(values(service_discover_consul('keystone', 'real'))),
  $keystone_internal_ips = sort(values(service_discover_consul('keystone-admin', 'real'))),
  $glance_ips            = sort(values(service_discover_consul('glance', 'real'))),
  $cinder_ips            = sort(values(service_discover_consul('cinder', 'real'))),
  $nova_ips              = sort(values(service_discover_consul('nova', 'real'))),
  $neutron_ips           = sort(values(service_discover_consul('neutron', 'real'))),
  $radosgw_ips           = sort(values(service_discover_consul('radosgw', 'real'))),
  $radosgw_port          = '80',
  $horizon_port          = '80',
  $horizon_https_port    = '443',
  $novncproxy_port       = '6080',
  $keystone_public_port  = '5000',
  $keystone_admin_port   = '35357',
  $glance_port           = '9292',
  $glance_registry_port  = '9191',
  $cinder_port           = '8776',
  $nova_port             = '8774',
  $neutron_port          = '9696',
  $metadata_port         = '8775',
  $nova_ec2_port         = '8773',
  $nova_ec2_enabled      = true,
  $metadata_enabled      = true,
  $nova_enabled          = true,
  $cinder_enabled        = true,
  $glance_enabled        = true,
  $neutron_enabled       = true,
  $keystone_enabled      = true,
  $novncproxy_enabled    = true,
  $radosgw_enabled       = true,
  $horizon_enabled       = true,
) {

  class { 'rjil::test::haproxy_openstack':
    horizon_ips           => $horizon_ips,
    keystone_ips          => $keystone_ips,
    keystone_internal_ips => $keystone_internal_ips,
    glance_ips            => $glance_ips,
    cinder_ips            => $cinder_ips,
    nova_ips              => $nova_ips,
    keystone_enabled      => $keystone_enabled,
    glance_enabled        => $glance_enabled,
    neutron_enabled       => $neutron_enabled,
  }

  Rjil::Haproxy_service {
    ssl => true,
  }

  rjil::test { 'haproxy.sh': }

  if $horizon_enabled {
    rjil::haproxy_service { 'horizon':
      balancer_ports    => $horizon_port,
      cluster_addresses => $horizon_ips,
      listen_options   =>  {
        'balance'      => 'source',
        'option'       => ['tcpka','abortonclose']
      },
    }
    rjil::haproxy_service { 'horizon-https':
      balancer_ports    => $horizon_https_port,
      cluster_addresses => $horizon_ips,
    }
  }


  if $radosgw_enabled {
    rjil::haproxy_service { 'radosgw':
      balancer_ports    => $radosgw_port,
      cluster_addresses => $radosgw_ips,
    }
  }

  if $novncproxy_enabled {
    rjil::haproxy_service { 'novncproxy':
      balancer_ports    => $novncproxy_port,
      cluster_addresses => $nova_ips,
      check_type        => 'tcp',
    }
  }

  if $keystone_enabled {
    rjil::haproxy_service { 'keystone':
      balancer_ports    => $keystone_public_port,
      cluster_addresses => $keystone_ips,
    }

    rjil::haproxy_service { 'keystone-admin':
      balancer_ports    => $keystone_admin_port,
      cluster_addresses => $keystone_internal_ips,
    }
  }

  if $neutron_enabled {
    rjil::haproxy_service { 'neutron':
      balancer_ports    => $neutron_port,
      cluster_addresses => $neutron_ips,
    }
  }

  if $glance_enabled {
    rjil::haproxy_service { 'glance':
      balancer_ports    => $glance_port,
      cluster_addresses => $glance_ips,
    }
    rjil::haproxy_service { 'glance-registry':
      balancer_ports    => $glance_registry_port,
      cluster_addresses => $glance_ips,
      check_type        => 'tcp',
    }
  }

  if $cinder_enabled {
    rjil::haproxy_service { 'cinder':
      balancer_ports    => $cinder_port,
      cluster_addresses => $cinder_ips,
    }
  }

  if $nova_enabled {
    rjil::haproxy_service { 'nova':
      balancer_ports    => $nova_port,
      cluster_addresses => $nova_ips,
    }
  }

  if $metadata_enabled {
    rjil::haproxy_service { 'metadata':
      balancer_ports    => $metadata_port,
      cluster_addresses => $nova_ips,
      ssl               => false,
    }
  }

  if $nova_ec2_enabled {

    rjil::haproxy_service { 'nova-ec2':
      balancer_ports    => $nova_ec2_port,
      cluster_addresses => $nova_ips,
      check_type        => 'tcp',
    }
  }

}
