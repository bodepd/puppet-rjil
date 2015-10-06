require 'spec_helper'

describe 'rjil::haproxy' do

  let :facts do
    {
      :osfamily       => 'Debian',
      :concat_basedir => '/tmp',
      :architecture   => 'amd64'
    }
  end


  it 'should install haproxy' do

    should contain_rjil__test('haproxy.sh')
    should contain_rjil__jiocloud__consul__service('haproxy').with({
      'tags' => []
    })
    should contain_rjil__jiocloud__logrotate('haproxy')
  end

  context 'consul_service_tags are provided' do
    let :params do
      {
        'consul_service_tags' => ['foo', 'bar']
      }
    end
    it 'should set set the tags on consul service' do
      should contain_rjil__jiocloud__consul__service('haproxy').with({
        'tags' => ['foo', 'bar']
      })
    end
  end
end
