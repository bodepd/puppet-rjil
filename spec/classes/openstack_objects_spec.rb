require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::openstack_objects' do

  let :params do
    {
      'identity_address' => 'address',
      'override_ips'     => ''
    }
  end
  let :hiera_data do
    {
      'keystone::roles::admin::email'          => 'foo@bar',
      'keystone::roles::admin::password'       => 'ChangeMe',
      'keystone::roles::admin::service_tenant' => 'services',
      'rjil::keystone::test_user::password'    => 'password',
      'cinder::keystone::auth::password'       => 'pass',
      'glance::keystone::auth::password'       => 'pass',
      'nova::keystone::auth::password'         => 'pass',
      'neutron::keystone::auth::password'      => 'pass'
    }
  end
  context 'when identity is not addressable' do
    it 'should fail at runtime' do
      should contain_runtime_fail('keystone_endpoint_not_resolvable').with({
        'fail'   => true,
      })
      should contain_class('openstack_extras::keystone_endpoints')
    end
  end
  context 'with defaults' do
    let :params do
      {
        :identity_address => 'address',
        :override_ips     => '10.10.10.10',
      }
    end

    it do
      should contain_rjil__service_blocker('lb.glance')
      should contain_rjil__service_blocker('lb.neutron')
      should contain_runtime_fail('keystone_endpoint_not_resolvable').with({
        'fail'   => false,
      })
      should contain_class('openstack_extras::keystone_endpoints')
      should contain_class('archive')
      should contain_archive('/usr/lib/jiocloud/cirros-0.3.3-x86_64-disk.img')
      should contain_class('tempest::provision')
    end
  end
  context 'without lb' do
    let :params do
      {
        :identity_address => 'address',
        :override_ips     => '10.10.10.10',
        :lb_available     => false,
      }
    end

    it do
      should contain_rjil__service_blocker('glance')
      should contain_rjil__service_blocker('neutron')
    end
  end
  context 'disable keystone' do
    before do
      params.merge!(:keystone_enabled => false)
    end
    it 'should not contain keystone objects' do
      should_not contain_class('openstack_extras::keystone_endpoints')
    end
  end
  context 'disable glance' do
    before do
      params.merge!(:glance_enabled => false)
    end
    it 'should not contain glance objects' do
      should_not contain_rjil__service_blocker('lb.glance')
      should_not contain_class('archive')
      should_not contain_archive('/usr/lib/jiocloud/cirros-0.3.3-x86_64-disk.img')
    end
  end
  context 'disable neutron' do
    before do
      params.merge!(:neutron_enabled => false)
    end
    it 'should not contain neutron objects' do
      should_not contain_rjil__service_blocker('lb.neutron')
    end
  end
  context 'disable tempest' do
    before do
      params.merge!(:tempest_enabled => false)
    end
    it 'should not contain tempest objects' do
      should_not contain_class('tempest::provision')
    end
  end
end
