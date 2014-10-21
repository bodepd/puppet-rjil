require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::logserver' do

  let :facts do
    {
      'osfamily'  => 'Debian',
      'lsbdistid' => 'ubuntu',
      'lsbdistcodename' => 'precise',
      'kernel'          => 'Linux',
      'operatingsystem' => 'Ubuntu',
      'operatingsystemrelease' => '12.04',
      'concat_basedir'  => '/tmp'
    }
  end

  let :hiera_data do
    {
      'rjil::logforwarder::cert' => 'CERT'
    }
  end

  let :params do
    {
      'forwarder_key' => 'FOOKEY'
    }
  end

  it 'should contain default resources' do
    should contain_class('rjil::logforwarder')
    should contain_class('logstash').with({
      'manage_repo'  => true,
      'repo_version' => '1.4',
      'java_install' => true,
    })
    should contain_class('elasticsearch').with({
      'manage_repo'  => true,
      'repo_version' => '1.1',
      'java_install' => true,
    })
    should contain_class('kibana3')
    should contain_file('/etc/pki/private/logstash-forwarder.key').with({
      'content' => 'FOOKEY'
    })
    should contain_logstash__configfile('lumberjack_input')
    should contain_logstash__configfile('lumberjack_output')
    should contain_logstash__configfile('syslog_filter')
    should contain_rjil__test('logserver.sh')
    should contain_rjil__jiocloud__consul__service('logserver')
  end

end
