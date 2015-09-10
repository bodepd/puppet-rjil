Puppet::Type.type(:service).provide :noop do
  desc "

  A provider that does absolutely nothing. I wrote it so that I could
  take out service definitions and replace them with docker containers.

  "

  # status just returs that the service is already in the correct state
  # so that no other method ever needs to be called
  def status
    resource[:ensure]
  end

  def restart
    # do nothing
  end

end

