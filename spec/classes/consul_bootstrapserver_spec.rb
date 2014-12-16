require 'spec_helper'
describe 'rjil::jiocloud::consul::bootstrapserver' do
  let :facts  do
    {
      :env             => 'testenv',
      :osfamily        => 'Debian',
      :operatingsystem => 'Ubuntu',
      :architecture    => 'x86_64',
      :lsbdistrelease  => '14.04',
      :concat_basedir  => '/tmp/',
      :operatingsystemrelease => '14.04',
      :consul_discovery_token => 'testtoken'
    }
  end

  describe 'default resources' do
    it 'should configure agent as server that bootstraps' do
      should contain_class('consul').with({
        'config_hash' => {
          'datacenter'          => 'testtoken',
          'data_dir'            => '/var/lib/consul-jio',
          'log_level'           => 'INFO',
          'enable_syslog'       => true,
          'disable_remote_exec' => true,
          'bind_addr'           => '0.0.0.0',
          'server'              => true,
          'bootstrap_expect'    => 1,
        }
      })
    end
  end
end
