require 'spec_helper'
describe 'zookeeper_cluster_merge_self' do
  it 'should be able to add a local host' do
    should run.with_params(
      ['server.277=foo:2888:3888'],
      '127.0.0.1',
      'host'
    ).and_return(['server.277=foo:2888:3888', 'server.1=host:2888:3888'])
  end
  it 'should not add existing local host entry' do
    should run.with_params(
      ['server.1=host:2888:3888'],
      '127.0.0.1',
      'host'
    ).and_return(['server.1=host:2888:3888'])

  end
end
