module Puppet::Parser::Functions
  newfunction(
    :generate_zookeeper_cluster_string,
    :type  => :rvalue,
    :doc   => <<-'EOS'

Given a hash of the form hostname => ip, and two ports, it converts it into
the form expected by zookeeper to build out a cluster definition.

[server.<last_octet_from_ip_address>=<hostname>:<leader_port>:<election_port>]

EOS
  ) do |args|

    address_hash  = args.shift || fail("Requires at least one argument")
    leader_port   = args.shift || 2888
    election_port = args.shift || 3888

    unless address_hash.class == Hash
      fail("First argument must be a Hash, not a: #{args.class}")
    end

    results = []

    address_hash.each do |k, v|
      ip_regexp = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
      id = ip_regexp.match(v)[4]
      res_str = "server.#{id}=#{k}:#{leader_port}:#{election_port}"
      results.push(res_str)
    end
    return results.sort

  end

end
