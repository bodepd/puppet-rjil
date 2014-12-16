require 'spec_helper'
describe 'rjil::jiocloud::consul::agent' do
  let :facts  do
    {
      :env                    => 'testenv',
      :hostname               => 'foohost',
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :architecture           => 'x86_64',
      :lsbdistrelease         => '14.04',
      :consul_discovery_token => 'testtoken'
    }
  end

  describe 'default resources' do
    it 'should configure agent as non-server' do
      should contain_class('consul').with({
        'config_hash' => {
          'datacenter'       => 'testtoken',
          'data_dir'         => '/var/lib/consul-jio',
          'log_level'        => 'INFO',
          'enable_syslog'       => true,
          'server'           => false,
          'disable_remote_exec' => true,
          'bind_addr'        => '0.0.0.0',
          'start_join'       => ['testtoken.service.consuldiscovery.linux2go.dk'],
        }
      })
    end
  end
end
