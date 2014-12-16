require 'spec_helper'
#require 'hiera-puppet-helper'

describe 'rjil::jiocloud::consul' do

  let :facts do
    {
      'env'                    => 'unit_test',
      'hostname'               => 'foohost',
      'osfamily'               => 'Debian',
      'operatingsystem'        => 'Ubuntu',
      'architecture'           => 'x86_64',
      'lsbdistrelease'         => '14.04',
      'consul_discovery_token' => 'testtoken'
    }
  end

  let :default_config_hash do
    {
      'datacenter'          => 'testtoken',
      'data_dir'            => '/var/lib/consul-jio',
      'log_level'           => 'INFO',
      'enable_syslog'       => true,
      'server'              => false,
      'disable_remote_exec' => true,
    }
  end

  context 'with defaults' do

    it 'should contain default resources' do
      should contain_class('dnsmasq')
      should contain_dnsmasq__conf('consul').with({
        'ensure'  => 'present',
        'content' => 'server=/consul/127.0.0.1#8600',
      })
      should contain_class('consul').with({
        'install_method'    => 'package',
        'ui_package_name'   => 'consul-web-ui',
        'ui_package_ensure' => 'absent',
        'bin_dir'           => '/usr/bin',
        'config_hash'       => default_config_hash,
      })
      should contain_exec('reload-consul').with({
        'command'     => "/usr/bin/consul reload",
        'refreshonly' => true,
        'subscribe'   => 'Service[consul]',
      })
      should_not contain_rjil__puppet__cert('foohost.consul.cert')
    end
  end

  context 'with encryption enabled' do
    let :params do
      {'encrypt' => 'foo'}
    end
    let :config_hash do
      default_config_hash.merge({'encrypt' => 'foo'})
    end

  end

  context 'with ssl enabled' do
    let :params do
      {'ssl' => true}
    end
    let :config_hash do
      default_config_hash.merge({
        'ca_file'         => '/home/consul/.puppet/ssl/certs/ca.pem',
        'cert_file'       => '/home/consul/.puppet/ssl/certs/foohost.consul.cert.pem',
        'key_file'        => '/home/consul/.puppet/ssl/private_keys/foohost.consul.cert.pem',
        'verify_incoming' => true,
        'verify_outgoing' => true,
      })
    end
    it 'should enable ssl' do
      should contain_class('consul').with({
        'config_hash'       => config_hash,
      })
      should contain_rjil__puppet__cert('foohost.consul.cert').with({
        'server' => 'localhost',
      })
    end
  end

  context 'with overrides' do

    let :params do
      {
        'override_hash' => {'server' => true}
      }
    end
    let :config_hash do
      default_config_hash.merge({'server' => true})
    end
    it 'should override server to true' do
      should contain_class('consul').with({
        'config_hash'       => config_hash,
      })
    end
  end

end
