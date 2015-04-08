require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::rabbitmq' do

  let :hiera_data do
    {
      'rabbitmq::manage_repos' => false,
      'rabbitmq::admin_enable' => false,
      'rabbitmq::delete_guest_user' => true,
      'rabbitmq::port' => '5672',
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
    }
  end

  let :params do
    {
      'cluster_nodes' => []
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/check_rabbitmq.sh')
      should contain_class('rabbitmq').with({
        'manage_repos' => false,
        'admin_enable' => false,
        'delete_guest_user' => true,
        'port' => '5672',
        'config_cluster' => true,
        'cluster_nodes'  => [],
      })
    end
  end

  context 'with custom MQ login' do
    let :params do
      {
        'rabbit_admin_user' => 'rabbit',
        'rabbit_admin_pass' => 'rabbit',
      }
    end

    it do
      should contain_Rabbitmq_user('rabbit') \
        .with_admin(true) \
        .with_password('rabbit')

      should contain_Rabbitmq_user_permissions('rabbit@/') \
        .with_configure_permission('.*') \
        .with_read_permission('.*') \
        .with_write_permission('.*')
    end
  end

end
