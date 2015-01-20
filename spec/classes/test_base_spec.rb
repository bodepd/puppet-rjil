describe 'rjil::test::base' do

  context 'with defaults' do

    it 'should create default resources' do

      should create_package('nagios-plugins').with({
        'ensure' => 'present',
      })
      should create_file('/usr/lib/jiocloud').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
      })
      should create_file('/usr/lib/jiocloud/tests').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
      })
      should create_file('/usr/lib/jiocloud/tests/service_checks').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
      })
      should create_file('/usr/lib/nagios/plugins/check_killall_0').with({
        'source' => 'puppet:///modules/rjil/tests/nagios_killall_0',
        'mode'   => '0755',
        'owner'  => 'root',
        'group'  => 'root',
      })

    end

  end

end
