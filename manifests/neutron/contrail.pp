#
# Class: rjil::neutron::contrail
#

# [* public_subnets *]
#   is a hash of subnetlogicalname => cidr
#   e.g { pub_subnet1 => '100.1.0.0/16'}
#
# [*seed*]
#   Used to specify that the current node is the seed. Only seed nodes
#   should perform object creation actions against the api to avoid
#   race conditions.
#
# NOTE: Public network will be created on services tenant. In order to specify
# specific tenant name on which public network created, keystone.conf required
# on neutron server which is not the case as of now.

class rjil::neutron::contrail(
  $keystone_admin_password,
  $fip_pools           = {},
  $contrail_api_server = 'real.neutron.service.consul',
  $rt_number           = 10000,
  $router_asn          = 64512,
  $seed                = true,
) {

  include ::rjil::neutron

  ##
  # Database connection is not required for contrail
  ##

  Neutron_config<| title == 'database/connection' |> {
    ensure => absent
  }

  ##
  # Subscribe neutron-server to contrailplugin.ini
  ##

  File['/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'] ~>
    Service['neutron-server']

  include rjil::contrail::server

  if $seed {
    ##
    # Create fip pools including creation of network, subnet, fip pool etc
    ##
    $fip_pool_defaults = {
                          keystone_admin_password => $keystone_admin_password,
                          contrail_api_server     => $contrail_api_server,
                          rt_number               => $rt_number,
                          router_asn              => $router_asn,
                          require                 => Service['contrail-api']
                        }
    create_resources(rjil::neutron::contrail::fip_pool,$fip_pools,$fip_pool_defaults)
  }
}
