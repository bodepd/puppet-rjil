require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::zookeeper' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
      :ipaddress       => '10.1.2.3',
      :hostname        => 'foo',
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/check_zookeeper.sh')
      should contain_class('zookeeper').with({
        'id'      => 3,
        'servers' => ['server.3=foo:2888:3888']
      })
      should contain_rjil__test__check('zookeeper').with({
        'type'    => 'tcp',
        'address' => '127.0.0.1',
        'port'    => 2181,
      })
      should contain_rjil__jiocloud__consul__service('zookeeper').with({
        'port' => 2181,
        'tags' => ['real', 'contrail'],
      })
      should contain_rjil__service_blocker('seed.zookeeper').with({})
      should contain_runtime_fail('zookeeper_no_seed').with_fail(true)
    end
  end

  context 'when we discover ourselves from consul' do
    let :params do
      {
        'hosts' => {'foo' => '10.1.2.3'}
      }
    end
    it 'should not add itself twice' do
      should contain_class('zookeeper').with({
        'id'      => 3,
        'servers' => ['server.3=foo:2888:3888']
      })
      should contain_runtime_fail('zookeeper_no_seed').with({
        'fail'    => true,
        'require' => 'Rjil::Service_blocker[seed.zookeeper]'
      })
    end
  end

  context 'when we find someone else from consul' do
    let :params do
      {
        'hosts' => {'seed' => '10.1.2.4'}
      }
    end
    it 'should add itself with seed to cluster' do
      should contain_class('zookeeper').with({
        'id'      => 3,
        'servers' => ['server.4=seed:2888:3888', 'server.3=foo:2888:3888']
      })
      should_not contain_runtime_fail('zookeeper_list_empty').with_fail(true)
    end
  end

  context 'when we are the seed' do

    let :params do
      {:seed => true}
    end
    it 'should configure as seed' do
      should contain_file('/usr/lib/jiocloud/tests/check_zookeeper.sh')
      should contain_class('zookeeper').with({
        'id'      => 3,
        'servers' => ['server.3=foo:2888:3888']
      })
      should contain_rjil__test__check('zookeeper').with({
        'type'    => 'tcp',
        'address' => '127.0.0.1',
        'port'    => 2181,
      })
      should contain_rjil__jiocloud__consul__service('zookeeper').with({
        'port' => 2181,
        'tags' => ['real', 'contrail', 'seed'],
      })
      should_not contain_rjil__service_blocker('seed.zookeeper')
      should_not contain_runtime_fail('zookeeper_list_empty')
    end
  end

end
