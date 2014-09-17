Vagrant.configure("2") do |config|

   ENV['http_proxy'] = 'http://10.22.3.1:3128'
   ENV['https_proxy'] = 'http://10.22.3.1:3128'

  config.vm.box      = 'ubuntu/trusty64'

  {
    :openstackclient => '15',
    :etcd            => '16',
    :haproxy         => '17',
    :apache          => '18',
    :db              => '19',
    :memcached       => '20',
    :keystone        => '21',
    :keystonewithdb  => '22',
  }.each do |node_name, number|

    config.vm.define(node_name) do |config|

      config.vm.synced_folder("hiera/", '/etc/puppet/hiera/')
      #config.vm.synced_folder("modules/", '/etc/puppet/modules/')

      config.vm.host_name = "#{node_name}.domain.name"

      if ENV['http_proxy']
        #config.vm.provision :shell, :inline => "echo 'export http_proxy=#{ENV['http_proxy']}'  > /etc/profile.d/proxy.sh"
        #if ENV['https_proxy']
        #  config.vm.provision :shell, :inline => "echo 'export https_proxy=#{ENV['https_proxy']}' >> /etc/profile.d/proxy.sh"
        #end
        config.vm.provision 'shell', :inline =>
        "echo \"Acquire::http { Proxy \\\"#{ENV['http_proxy']}\\\" }\" > /etc/apt/apt.conf.d/03proxy"
      end

      # run apt-get update and install pip
      unless ENV['NO_APT_GET_UPDATE'] == 'true'
        config.vm.provision 'shell', :inline =>
        'apt-get update; apt-get install -y git curl;'
      end

      # upgrade puppet
      config.vm.provision 'shell', :inline =>
        'release=$(lsb_release -cs);wget -O puppet.deb http://apt.puppetlabs.com/puppetlabs-release-${release}.deb;dpkg -i puppet.deb;apt-get update;apt-get install -y puppet-common=3.6.2-1puppetlabs1'

      config.vm.network "private_network", :ip => "10.22.3.#{number}"
      config.vm.network "private_network", :ip => "10.22.4.#{number}"
      config.vm.provision(:puppet) do |puppet|
        puppet.manifests_path    = '.'
        puppet.manifest_file     = 'site.pp'
        puppet.module_path       = ['modules', '../']
        puppet.options           = ['--hiera_config=/etc/puppet/hiera/hiera.yaml', "--certname=#{node_name}"]
        puppet.facter            = { 'env' => 'vagrant' }
      end
      config.vm.provision 'shell', :inline => 'run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/'
    end
  end
end
