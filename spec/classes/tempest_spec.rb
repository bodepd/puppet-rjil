require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::tempest' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
    }
  end

  let :hiera_data do
    {
      'tempest::tempest_repo_uri'    => 'https://github.com/openstack/tempest.git',
      'tempest::image_name'          => 'cirros',
      'tempest::image_name_alt'      => 'cirros',
      'tempest::flavor_ref'          => 1,
      'tempest::admin_password'      => 'tempest_admin',
      'tempest::admin_username'      => 'tempest_admin',
      'tempest::tenant_name'         => 'tempest',
      'tempest::username'            => 'tempest',
      'tempest::password'            => 'tempest',
      'tempest::identity_uri'        => 'http://identity.url',
      'tempest::neutron_available'   => true,
      'tempest::public_network_name' => 'net',
      'tempest::fixed_network_name'  => 'net_tempest',
      'tempest::setup_venv'          => true,
      'rjil::tempest::keystone_admin_token' => 'token',
#      'tempest::provision::imagename'       => 'cirros',
#      'tempest::provision::tenantname'      => 'tempest',
#      'tempest::provision::username'        => 'tempest_user',
#      'tempest::provision::admin_username'  => 'tempest_admin',
#      'tempest::provision::networkname'     =>
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/etc/keystone')

      should contain_file('/etc/keystone/keystone.conf')

      should contain_keystone_config('DEFAULT/admin_token').with_value('token')

      should contain_keystone_config('DEFAULT/admin_endpoint').with_value('http://lb.keystone.service.consul:35357/v2.0')

      should contain_file('/etc/glance')

      should contain_file('/etc/glance/glance-api.conf')

      should contain_glance_api_config('keystone_authtoken/auth_host').with_value('lb.keystone.service.consul')

      should contain_glance_api_config('keystone_authtoken/auth_port').with_value('35357')

      should contain_glance_api_config('keystone_authtoken/auth_protocol').with_value('http')

      should contain_glance_api_config('keystone_authtoken/admin_tenant_name').with_value('services')

      should contain_glance_api_config('keystone_authtoken/admin_user').with_value('glance')

      should contain_glance_api_config('keystone_authtoken/admin_password').with_value('glance')

       should contain_file('/etc/neutron')

      should contain_file('/etc/neutron/neutron.conf')

      should contain_neutron_config('keystone_authtoken/auth_host').with_value('lb.keystone.service.consul')

      should contain_neutron_config('keystone_authtoken/auth_port').with_value('35357')

      should contain_neutron_config('keystone_authtoken/auth_protocol').with_value('http')

      should contain_neutron_config('keystone_authtoken/admin_tenant_name').with_value('services')

      should contain_neutron_config('keystone_authtoken/admin_user').with_value('neutron')

      should contain_neutron_config('keystone_authtoken/admin_password').with_value('neutron')
      should contain_class('tempest::provision')
      should contain_class('tempest')
    end
  end

end
