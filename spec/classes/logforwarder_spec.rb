require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::logforwarder' do

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

  let :params do
    {
      'cert' => 'CERT'
    }
  end

  it 'should contain default resources' do
    ['/etc/pki', '/etc/pki/certs', '/etc/pki/private'].each do |x|
      should contain_file(x).with_ensure('directory')
    end
    should contain_file('/etc/pki/certs/logstash-forwarder.crt').with({
      'content' => 'CERT'
    })
    should contain_class('logstashforwarder::repo')
    should contain_package('logstash-forwarder').with({
      'ensure' => 'present',
    })
    should contain_logstashforwarder_config('lsf-config').with({
      'content' =>
'',
      'path'    => '/etc/logstash-forwarder',
    })
    should contain_logstashforwarder__file('syslog')
    should contain_file('/etc/init.d/logstashforwarder')
    should contain_service('logstash-forwarder')
    should contain_file_line('syslog_add_pri').with({
      'line' => '$template  TraditionalWithPRI,"<%PRI%>%timegenerated% %HOSTNAME% %syslogtag%%msg%\n"',
      'path' => '/etc/rsyslog.conf',
      'after' => 'ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat'
    })
    should contain_file_line('syslog_set_pri_default').with({
      'line'  => '$ActionFileDefaultTemplate TraditionalWithPRI',
      'path'  => '/etc/rsyslog.conf',
      'after' => 'template  TraditionalWithPRI',
    })
    should contain_service('rsyslog').with_ensure('running')
  end

end
