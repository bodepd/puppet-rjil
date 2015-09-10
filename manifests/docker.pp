#
# class for installing docker
#
class rjil::docker {

#
# maybe we should verify that the kernel is the right version or fail?
#
  class { '::docker':
    # don't muck with the kernel
    manage_kernel => false,
  }

}
