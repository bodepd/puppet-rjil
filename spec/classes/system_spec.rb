require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::system' do

  let :facts do
    {
      'lsbdistid'       => 'ubuntu',
      'lsbdistcodename' => 'trusty',
      'osfamily'        => 'Debian',
      'interfaces'      => 'eth0',
    }
  end

  let :hiera_data do
    {
      'rjil::system::accounts::local_users' =>
        {
          'u1' => {'realname' => 'u1', 'sshkeys' => 'ssh-dsskey'},
          'u2' => {'realname' => 'u2', 'sshkeys' => 'ssh-dsskey'},
          'u3' => {'realname' => 'u3', 'sshkeys' => 'ssh-dsskey'},
        },
      'rjil::system::accounts::active_users' => ['u2','u3'],
      'rjil::system::accounts::sudo_users' => ['u3'],
      'ntp::servers' => ['server1']
    }
  end
  context 'with defaults' do
    it  do
      should contain_file('/etc/issue')
      should contain_file('/etc/issue.net')
      should contain_file('/usr/lib/jiocloud/tests/check_timezone.sh')
      should contain_class('timezone')
      should contain_class('rjil::system::apt')
      should contain_class('rjil::system::accounts')
    end
  end
end
