require 'set'
module Puppet::Parser::Functions
  newfunction(
    :zookeeper_cluster_merge_self,
    :type  => :rvalue,
    :doc   => <<-'EOS'

Given a zookeeper cluster array, adds the localhosts information if not already
present.

# TODO add a lot more error checking to ensure that id and hostnames are all unique

EOS
  ) do |args|

    address_array = args.shift || fail("Requires at least one argument")
    local_ip      = args.shift || fail('Must pass second argument: local_ip')
    hostname      = args.shift || fail('Must pass third argument: hostname')
    leader_port   = args.shift || 2888
    election_port = args.shift || 3888

    zk_cluster_set = Set.new(address_array)

    ip_regexp = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
    id = ip_regexp.match(local_ip)[4]
    res_str = "server.#{id}=#{hostname}:#{leader_port}:#{election_port}"

    res = zk_cluster_set.add?(res_str)
    return res.to_a.sort if res
    return address_array.sort if ! res

  end

end
