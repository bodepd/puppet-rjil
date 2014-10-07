module Puppet::Parser::Functions
  newfunction(
    :create_mon_hash,
    :type  => :rvalue,
    :arity => 3,
    :doc   => <<-EOS

Accepts the following arguments:

* local short hostname
* mon address
* addresses of members

Creates a hash of the mon objects that should be created
as ceph::conf::mon_config object. Appends the leader
mon address to the list of other members and ensures
that one of those addresses matches the local hostname.

Example:
  create_mon_hash(myhost, 10.0.0.2, [10.0.0.2, 10.0.0.3])

returns:

{
  myhost    => { 'mon_addr' => 10.0.0.2 },
  10-0-0-2 => { 'mon_addr' => 10.0.0.3 }
}

    EOS
  ) do |args|

    hostname, addr, member_array = args

    ret_hash = {}

    unless member_array.class == Array
      raise(Puppet::ParseError, "Member array only expects an array, not #{member_array.class}")
    end

    member_array.each do |a|
      if a == addr
        ret_hash[hostname] = {'mon_addr' => addr}
      else
        ret_hash[a.gsub('.', '-')] = {'mon_addr' => a}
      end
    end

    return ret_hash

  end
end
