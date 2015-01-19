require 'spec_helper'

describe 'rjil::jiocloud::jenkins::slave' do

  let :facts do
    {
      'osfamily' => 'Debian',
      'lsbdistcodename' => 'natty',
      'lsbdistcodename' => 'precise',
      'lsbdistid'       => 'ubuntu',
    }
  end

  it 'should configure defaults' do
    should contain_class('rjil::jiocloud::jenkins')
    should contain_group('jiojenkins').with_ensure('present')
    should contain_user('jiojenkins')
  end

end
