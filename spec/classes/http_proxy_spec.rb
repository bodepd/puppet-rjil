require 'spec_helper'

describe 'rjil::http_proxy' do

  it 'should configure a default proxy' do
    should contain_class('squid3').with({
      'cache_dir' => ['ufs /var/spool/squid3 10000 16 256'],
      'maximum_object_size'           => '50096 KB',
      'maximum_object_size_in_memory' => '5012 KB',
    })
    should contain_service('squid3_service').with_provider(
      'upstart'
    )
    should contain_rjil__jiocloud__consul__service('proxy').with({
      'port'          => '3128',
      'tags'          => ['real'],
      'check_command' => "/usr/lib/nagios/plugins/check_http -H localhost -p 3128",
    })
  end


end
