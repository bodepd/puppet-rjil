require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::neutron::contrail' do
  let:facts do
    {
      :operatingsystem        => 'Debian',
      :operatingsystemrelease => '14.04',
      :osfamily               => 'Debian',
      :concat_basedir         => '/tmp',
      :hostname               => 'node1',
      :interfaces             => 'eth0,lo',
      :ipaddress_eth0         => '10.1.1.100',
      :lsbdistid              => 'ubuntu',
      :lsbdistcodename        => 'trusty',
    }
  end
  let :hiera_data do
    {
      'neutron::server::auth_host'                  => '10.1.1.10',
      'neutron::server::auth_password'              => 'pass',
      'openstack_extras::auth_file::admin_password' => 'pw',
      'contrail::keystone_host'                     => '10.1.1.1',
      'contrail::keystone_admin_token'              => 'token',
      'contrail::keystone_admin_password'           => 'pass',
      'contrail::keystone_auth_password'           => 'pass',
      'neutron::rabbit_password'                    => 'guest',
      'neutron::core_plugin'                        => 'coreplugin',
      'neutron::service_plugins'                    => ['serviceplugin1'],
      'neutron::quota::quota_driver'                => 'contraildriver',
      'rjil::neutron::api_extensions_path'          => 'extensionspath',
      'rjil::neutron::service_provider'             => 'serviceprovider',
    }
  end

  context 'with public cidr' do

    let :params do
      {
        'public_cidr'             => '1.1.1.0/24',
        'keystone_admin_password' => 'pass',
      }
    end

    it 'should configure public network' do

      should contain_neutron_network('public').with({
        'ensure'          => 'present',
        'router_external' => true
      })
      should contain_neutron_subnet('pub_subnet1').with({
        'ensure'       => 'present',
        'cidr'         => '1.1.1.0/24',
        'network_name' => 'public'
      })
      should contain_contrail_rt('default-domain:services:public').with({
        'ensure'             => 'present',
        'rt_number'          => 10000,
        'router_asn'         => 64512,
        'api_server_address' => 'real.neutron.service.consul',
        'admin_password'     => 'pass',
        'require'            => 'Neutron_network[public]',
      })
    end

  end
  context 'with seed set to false' do

    let :params do
      {
        'public_cidr'             => '1.1.1.0/24',
        'keystone_admin_password' => 'pass',
        'seed'                    => false,
      }
    end
    it 'should not create objects' do
      should_not contain_neutron_network('public')
      should_not contain_neutron_subnet('pub_subnet1')
      should_not contain_contrail_rt('default-domain:services:public')
    end
  end
end
