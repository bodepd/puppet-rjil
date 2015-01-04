require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::db' do

  let :hiera_data do
    {
      'rjil::db::mysql_datadir'   => '/tmp/mysql',
      'rjil::db::mysql_root_pass' => 'testpass',
      'rjil::db::dbs'             => { 'nova' => { 'db' => 'testdb', 'user' => 'testuser', 'pass' => 'twst' }, }
    }
  end

  let(:facts) do
    {
      :osfamily       => 'Debian',
      :processorcount => '40',
      :root_home      => '/etc/mysql',
      :lsbdistrelease  => '14.04',
      :lsbdistcodename => 'trusty',
      :operatingsystem => 'Ubuntu',
      :lsbdistid       => 'Ubuntu',
    }
  end

  describe 'default resources' do
    it 'should contain default resources' do
      should contain_file('/etc/consul/mysql.json').with_content(/\"port\": 3306/)
      should contain_file('/usr/lib/jiocloud/tests/mysql.sh')
      should contain_class('mysql::server').with(
        {
          'root_password'    => 'testpass',
          'override_options' => {'mysqld'  =>
            {
              'max_connections' => '1024',
              'datadir'         => '/tmp/mysql',
              'bind-address'    => '0.0.0.0',
            }
          },
        }
      )
      should contain_file('/tmp/mysql').with(
        {
          'ensure'  => 'directory',
          'owner'   => 'mysql',
          'group'   => 'mysql',
        }
      )
      should contain_exec('mysql_install_db').with(
        {
          'command'   => 'mysql_install_db --datadir=/tmp/mysql --user=mysql',
          'creates'   => '/tmp/mysql/mysql',
        }
      )
      should_not contain_package('xfsprogs')
      should_not contain_exec('mkfs_/dev/sdb')
      should_not contain_file_line('fstab_/dev/sdb')
      should_not contain_exec('mount_/dev/sdb')
      should contain_file('/etc/mysql/debian.cnf').with(
        {
          'ensure' => 'link',
          'target' => '/etc/mysql/.my.cnf',
        }
      )
    end
  end


  describe 'with mysql_data_disk' do

    let :params do
      {
        :mysql_data_disk     => '/dev/sdb',
      }
    end
    it 'should contain mysql_data_disk specific resources' do
      should contain_package('xfsprogs').with(
        {
          'ensure' => 'present'
        }
      )
      should contain_exec('mkfs_/dev/sdb').with_command( /mkfs.xfs -f -d agcount=40 -l[\s\t]+size=1024m -n size=64k \/dev\/sdb/ )
      should contain_file_line('fstab_/dev/sdb').with(
        {
          'line' => '/dev/sdb /tmp/mysql xfs rw,noatime,inode64 0 2',
          'require' => 'Exec[mkfs_/dev/sdb]',
        }
      )
      should contain_exec('mount_/dev/sdb').with(
        {
          'command'   => 'mount /dev/sdb',
          'unless'    => 'df /tmp/mysql | grep /dev/sdb',
          'require'   => 'File_line[fstab_/dev/sdb]',
        }
      )
      should contain_exec('mysql_install_db').with(
        {
          'command'   => 'mysql_install_db --datadir=/tmp/mysql --user=mysql',
          'creates'   => '/tmp/mysql/mysql',
          'unless'    => 'test -d /tmp/mysql/mysql',
          'require'   => ['Package[mysql-server]','Exec[mount_/dev/sdb]'],
        }
      )
      should_not contain_exec('mysql_install_db').with(
        {
          'require' => 'Package[mysql-server]',
        }
      )
    end
  end
end
