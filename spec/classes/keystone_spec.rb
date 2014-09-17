require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::keystone' do

  let :hiera_data do
    {
      'keystone::admin_token'            => '123',
      'keystone::roles::admin::email'    => 'foo@bar.com',
      'keystone::roles::admin::password' => 'pass',
      'cinder::keystone::auth::password' => 'pass',
      'glance::keystone::auth::password' => 'pass',
      'nova::keystone::auth::password' => 'pass',
      'neutron::keystone::auth::password' => 'pass',
    }
  end

  describe 'default resources' do
    it 'should contain default resources' do
      should contain_file('/usr/lib/jiocloud/tests/keystone.sh')
      should contain_class('keystone')
      should_not contain_apache__vhost('keystone')
      should_not contain_apache__vhost('keystone-admin')
    end
  end

  describe 'with ssl' do

    let :params do
      {
        'ssl'            => true,
        'public_address' => '10.0.0.2',
        'admin_email'    => 'root@rjil.com',
        'admin_port'     => '35756',
      }
      it 'should contain ssl specific resources' do
        should contain_class('apache')
        should contain_apache__vhost('keystone').with(
          {
            'servername'  => '10.0.0.2',
            'serveradmin' => 'root@rjil.com',
            'port'        => '443',
            'ssl'         => true,
            'proxy_pass'  => [ { 'path' => '/', 'url' => "http://localhost:5000/"  } ]
          }
        )
        should contain_apache__vhost('keystone-admin').with(
          {
            'servername'  => '10.0.0.2',
            'serveradmin' => 'root@rjil.com',
            'port'        => '35356',
            'ssl'         => true,
            'proxy_pass'  => [ { 'path' => '/', 'url' => "http://localhost:35357/"  } ]
          }
        )
      end
    end

  end
  describe 'with ceph auth' do

    let :params do
      {
        'ceph_radosgw_enabled'            => true,
      }
      it { should contain_class('rjil::keystone::radosgw') }
    end
  end

  describe 'with caching' do
    let :params do
       {
         'cache_enabled'          => true,
         'cache_backend'          => 'dogpile.cache.memcached',
         'cache_backend_argument' => 'url:127.0.0.1:11211',
       }
    end
    it 'should configure caching' do
      should contain_keystone_config('cache/enabled').with_value('True')
      should contain_keystone_config('cache/config_prefix').with_value('cache.keystone')
      should contain_keystone_config('cache/expiration_time').with_value('600')
      should contain_keystone_config('cache/cache_backend').with_value('dogpile.cache.memcached')
      should contain_keystone_config('cache/backend_argument').with_value('url:127.0.0.1:11211')
    end
  end

end
