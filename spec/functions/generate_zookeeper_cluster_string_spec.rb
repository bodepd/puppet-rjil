require 'spec_helper'
describe 'generate_zookeeper_cluster_string' do
  it 'should fail if no args are passed' do
    expect do
      should run.with_params([]).and_return('1')
    end.to raise_error(Puppet::Error, /First argument must be a Hash/)
  end
  context 'host list' do
    it do
      should run.with_params({'foo' => '172.168.9.277'}).and_return(['server.277=foo:2888:3888'])
      should run.with_params({'foo' => '172.168.9.277', 'bar' => '127.0.0.1'}).and_return(['server.1=bar:2888:3888', 'server.277=foo:2888:3888'])
    end
  end
end
