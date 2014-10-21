require 'spec_helper'

describe 'rjil::jiocloud' do

  let :facts do
    {
      'architecture'    => 'amd64',
      'operatingsystem' => 'Ubuntu',
      'lsbdistrelease'  => '14.04',
      'lsbdistid'       => 'Ubuntu',
      'lsbdistcodename' => 'precise',
      'osfamily'        => 'Debian',
    }
  end

  context 'Default install' do
    it 'should with defaults' do
      should contain_class('rjil::jiocloud::consul::agent')
      should contain_cron('maybe-upgrade').with({
        'command' => 'run-one /usr/local/bin/maybe-upgrade.sh',
        'user'    => 'root',
      })
    end
  end

  context 'with invalid consul role' do
    let :params do
      {
        'consul_role' => 'blah'
      }
    end
    it 'should fail' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /consul role should be agent\|server\|bootstrapserver, not blah/)
    end
  end

  context 'puppetconf deprecation cleanup' do
    it { should contain_ini_setting('templatedir').with({
      'ensure'  => 'absent',
      'path'    => '/etc/puppet/puppet.conf',
      'section' => 'main',
      'setting' => 'templatedir',
    })}
  end
  context 'when there is data to be eaten' do
    let :params do
      {
        'eat_data' => true
      }
    end
    it 'should configure for data eating' do
      should contain_cron('maybe-upgrade').with({
        'command' => 'run-one eatmydata /usr/local/bin/maybe-upgrade.sh',
        'user'    => 'root',
      })
      should contain_package('eatmydata').with_ensure('present')
    end

  end
end
