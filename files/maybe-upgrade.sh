#!/bin/bash

discovery_token=$(facter etcd_discovery_token)
# Exit codes:
# 0: Yup, there's an update
# 1: No, no updates
# 2: Could not reach etcd, so we don't know
# 3: Could not reach etcd, but we also haven't been initialised ourselves.
python -m jiocloud.orchestrate --discovery_token=$discovery_token pending_update
rv=$?

run_puppet() {
        puppet apply --detailed-exitcodes --logdest=syslog `puppet config print manifestdir`/site.pp
        python -m jiocloud.orchestrate --discovery_token=$discovery_token update_own_status puppet $?
}

validate_service() {
        run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/
        python -m jiocloud.orchestrate --discovery_token=$discovery_token update_own_status validation $?
}

if [ $rv -eq 0 ]
then
       pending_version=$(python -m jiocloud.orchestrate --discovery_token=$discovery_token current_version)
       apt-get update
       apt-get dist-upgrade -o Dpkg::Options::="--force-confold" -y
       run_puppet
       python -m jiocloud.orchestrate local_version $pending_version
elif [ $rv -eq 1 ]
then
       :
elif [ $rv -eq 2 ]
then
       :
elif [ $rv -eq 3 ]
then
       # Maybe we're the first etcd node (or some other weirdness is going on).
       # Let's just run Puppet and see if things normalize
       run_puppet
fi
validate_service
python -m jiocloud.orchestrate --discovery_token=$discovery_token update_own_info
