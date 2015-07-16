require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::test::keystone' do

  let :hiera_data do
    {
      'openstack_extras::auth_file::admin_password' => 'pass'
    }
  end

  context 'with defaults' do
    it 'should contain default resources' do
      should contain_class('rjil::test::base')
      should contain_class('openstack_extras::auth_file')
      should contain_file('/usr/lib/jiocloud/tests/keystone.sh') \
        .with_content(/keystone catalog/) \
        .with_owner('root') \
        .with_group('root') \
        .with_mode('0755')
      should contain_package('python-keystoneclient')
    end
  end

end
