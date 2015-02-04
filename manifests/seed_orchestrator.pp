#
# used to implement an orchestration pattern for deploying clusters
# that require an initial seed node for bootstrapping
# = Parameters
#
# [port] Port that service runs. Used to configure service registration and validation checks.
# [check_type] Type of check to run, accepts http, tcp, and proc
# [tags] Defaults tags to use for registered services
# [seed] Whether the specified node is the cluster seed
# [dep_resources] Resources that should not be eecuted on non-seed nodes until
#   they can connect to the seed
# [follower_fail] If followers have failed to find a seed
define rjil::seed_orchestrator(
  $port              = -1,
  $check_type        = 'tcp',
  $tags              = ['real'],
  $seed              = false,
  $dep_resources     = [],
  $follower_fail     = false,
  $follower_fail_msg = "${name} follower failed"
) {

  if $seed {
    # tag ourselves as the cluster seed
    $service_tags = concat($tags, ['seed'])
  } else {
    $service_tags = $tags
    # Block until seed address resolves (this ensures that we should
    # only fail at most once)
    ensure_resource('rjil::service_blocker', "seed.${name}", {})
    runtime_fail {"${name}_no_seed":
      fail    => $follower_fail,
      message => "Follower ${name} failed",
      before  => $dep_resources,
      require => Rjil::Service_blocker["seed.${name}"]
    }
  }

  rjil::test::check { $name:
    type    => $check_type,
    address => '127.0.0.1',
    port    => $port,
  }

  rjil::jiocloud::consul::service { $name:
    port          => $port,
    tags          => $service_tags,
  }

}
