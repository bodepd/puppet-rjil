require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::haproxy::openstack' do

  let :facts do
    {
      'osfamily' => 'Debian',
    }
  end

  let :hiera_data do
    {
      'openstack_extras::auth_file::admin_password' => 'pass'
    }
  end

  let :service_list do
    {
      'horizon'         => '80',
      'horizon-https'   => '443',
      'novncproxy'      => '6080',
      'keystone'        => '5000',
      'keystone-admin'  => '35357',
      'glance'          => '9292',
      'glance-registry' => '9191',
      'cinder'          => '8776',
      'nova'            => '8774',
      'metadata'        => '8775',
      'nova-ec2'        => '8773',
      'radosgw'         => '80',
    }
  end

  let :params do
    {
      'horizon_ips'           => [],
      'keystone_ips'          => [],
      'keystone_internal_ips' => [],
      'glance_ips'            => [],
      'cinder_ips'            => [],
      'nova_ips'              => [],
      'neutron_ips'           => [],
      'radosgw_ips'           => [],
    }
  end

  describe 'with default parameters' do

    it 'should build default load balancing rules' do
      service_list.each do |name, port|
        should contain_rjil__haproxy_service(name).with(
          {
            'balancer_ports'    => port,
            'cluster_addresses' => [],
          }
        )
      end

      should contain_rjil__haproxy_service('horizon').with_listen_options(
        {
          'balance'      => 'source',
          'option'       => ['tcpka','abortonclose']
        }
      )
      should contain_rjil__haproxy_service('metadata').with_listen_options(
        {
          'balance'      => 'roundrobin',
          'option'       => 'abortonclose'
        }
      )

    end

  end

  describe 'with default parameters' do
    it 'should create all ha proxy services' do
      ['horizon', 'horizon-https', 'radosgw', 'novncproxy', 'keystone', 'keystone-admin', 'neutron', 'glance', 'glance-registry', 'cinder', 'nova', 'metadata', 'nova-ec2'].each do |x|
        should contain_rjil__haproxy_service(x)
      end
    end
  end
  describe 'when services are disabled' do
    before do
      params.merge!(
        'nova_ec2_enabled'   => false,
        'metadata_enabled'   => false,
        'nova_enabled'       => false,
        'cinder_enabled'     => false,
        'glance_enabled'     => false,
        'neutron_enabled'    => false,
        'keystone_enabled'   => false,
        'novncproxy_enabled' => false,
        'radosgw_enabled'    => false,
        'horizon_enabled'    => false,
      )
    end
    it 'should create all ha proxy services' do
      ['horizon', 'horizon-https', 'radosgw', 'novncproxy', 'keystone', 'keystone-admin', 'neutron', 'glance', 'glance-registry', 'cinder', 'nova', 'metadata', 'nova-ec2'].each do |x|
        should_not contain_rjil__haproxy_service(x)
      end
    end
  end

end
