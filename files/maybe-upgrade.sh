#!/bin/bash

# When we're run from cron, we only have /usr/bin and /bin. That won't cut it.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Exit codes:
# 0: Yup, there's an update
# 1: No, no updates
# 2: Could not reach etcd, so we don't know
# 3: Could not reach etcd, but we also haven't been initialised ourselves.
python -m jiocloud.orchestrate pending_update
rv=$?

run_puppet() {
        # ensure that our service catalog hiera data is available
        # now run puppet
        puppet apply --detailed-exitcodes --logdest=syslog `puppet config print manifestdir`/site.pp
        # publish the results of that run
        ret_code=$?
        python -m jiocloud.orchestrate update_own_status puppet $ret_code
        if [[ $ret_code = 1 || $ret_code = 4 || $ret_code = 6 ]]; then
                echo "Puppet failed with return code ${ret_code}"
                sleep 5
                exit 1
        fi
}

validate_service() {
        run-parts --regex=. --verbose --exit-on-error  --report /usr/lib/jiocloud/tests/
        ret_code=$?
        python -m jiocloud.orchestrate update_own_status validation $ret_code
        if [[ $ret_code != 0 ]]; then
                echo "Validation failed with return code ${ret_code}"
                sleep 5
                exit 1
        fi
}

if [ $rv -eq 0 ]
then
       pending_version=$(python -m jiocloud.orchestrate current_version)
       echo current_version=$pending_version > /etc/facter/facts.d/current_version.txt

       # Update apt sources to point to new snapshot version
       puppet apply --logdest=syslog -e 'include rjil::system::apt'

       apt-get update
       apt-get dist-upgrade -o Dpkg::Options::="--force-confold" -y
       run_puppet
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
python -m jiocloud.orchestrate local_version $pending_version
python -m jiocloud.orchestrate update_own_info
