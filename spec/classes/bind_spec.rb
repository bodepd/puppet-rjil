require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::bind' do
  let :facts do
    {
      'osfamily'       => 'Debian',
      'ipaddress'      =>  '192.100.1.3',
      'concat_basedir' => '/tmp',
    }
  end
  it 'should configure bind' do
    should contain_class('bind')
    should contain_rjil__test__check('dns').with({
      'address' => '192.100.1.3',
      'type'    => 'dns',
      'port'    => 53,
    })
    should contain_rjil__jiocloud__consul__service('dns').with({
      'tags'          => ['real'],
      'port'          => 53,
    })
    should contain_file('/etc/bind/named.conf.options')
  end
end
