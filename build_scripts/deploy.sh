#!/bin/bash -xe


. ${env_file:-/var/lib/jenkins/cloud.${env}.env}

if ! [ -e venv ]
then
    virtualenv venv
    . venv/bin/activate
    pip install -e git+https://github.com/JioCloud/python-jiocloud#egg=jiocloud
    deactivate
fi

. venv/bin/activate

# this is here to allow a user to override the command used for
# the timeout function just incase it happens to be gtimeout
timeout=${timeout_command:-timeout}

if [ -z "${etcd_discovery_token}" ]
then
    etcd_discovery_token=$(python -m jiocloud.orchestrate new_discovery_token)
fi

if [ -z "${env}" ]
then
    env='acceptance'
fi

cat <<EOF >userdata.txt
#!/bin/bash
release="\$(lsb_release -cs)"
wget -O puppet.deb http://apt.puppetlabs.com/puppetlabs-release-\${release}.deb
dpkg -i puppet.deb
apt-get update
apt-get install -y puppet
apt-get install -y software-properties-common
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 85596F7A
add-apt-repository "deb http://jiocloud.rustedhalo.com/ubuntu/ \${release} main"
apt-get update
apt-get install puppet-jiocloud
if [ -n "${puppet_modules_source_repo}" ]; then
  apt-get install -y git
  git clone ${puppet_modules_source_repo} /tmp/rjil
  if [ -n "${puppet_modules_source_branch}" ]; then
    pushd /tmp/rjil
    git checkout ${puppet_modules_source_branch}
    popd
  fi
  gem install librarian-puppet-simple --no-ri --no-rdoc;
  mkdir -p /etc/puppet/manifests.overrides
  cp /tmp/rjil/site.pp /etc/puppet/manifests.overrides/
  mkdir -p /etc/puppet/hiera
  cp /tmp/rjil/hiera/hiera.yaml /etc/puppet
  cp -Rvf /tmp/rjil/hiera/data /etc/puppet/hiera
  mkdir -p /etc/puppet/modules.overrides/rjil
  cp -Rvf /tmp/rjil/* /etc/puppet/modules.overrides/rjil/
  librarian-puppet install --puppetfile=/tmp/rjil/Puppetfile --path=/etc/puppet/modules.overrides
  puppet apply -e "ini_setting { modulepath: path => \"/etc/puppet/puppet.conf\", section => main, setting => modulepath, value => \"/etc/puppet/modules.overrides:/etc/puppet/modules\" }"
  puppet apply -e "ini_setting { manifestdir: path => \"/etc/puppet/puppet.conf\", section => main, setting => manifestdir, value => \"/etc/puppet/manifests.overrides\" }"
fi
sudo mkdir -p /etc/facter/facts.d
echo 'etcd_discovery_token='${etcd_discovery_token} > /etc/facter/facts.d/etcd.txt
echo 'env='${env} > /etc/facter/facts.d/env.txt
puppet apply --debug -e "include rjil::jiocloud"
EOF

python -m jiocloud.apply_resources apply --key_name=${KEY_NAME:-soren} --project_tag=test${BUILD_NUMBER} environment/cloud.${env}.yaml userdata.txt

if [ -n "$floating_ip" ]
then
	nova floating-ip-associate etcd1_test${BUILD_NUMBER} ${floating_ip}
fi

ip=$(python -m jiocloud.utils get_ip_of_node etcd1_test${BUILD_NUMBER})

$timeout 600 bash -c "while ! python -m jiocloud.orchestrate --host ${ip} ping; do sleep 5; done"

$timeout 600 bash -c "while ! ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ssh_user:-jenkins}@${ip} python -m jiocloud.orchestrate trigger_update ${BUILD_NUMBER}; do sleep 5; done"

$timeout 600 bash -c "while ! python -m jiocloud.apply_resources list --project_tag=test${BUILD_NUMBER} environment/cloud.${env}.yaml | sed -e 's/_/-/g' | python -m jiocloud.orchestrate --host ${ip} verify_hosts ${BUILD_NUMBER} ; do sleep 5; done"
$timeout 600 bash -c "while ! python -m jiocloud.orchestrate --host ${ip} check_single_version -v ${BUILD_NUMBER} ; do sleep 5; done"
# make sure that there are not any failures
if ! python -m jiocloud.orchestrate --host ${ip} get_failures; then
  echo "Failures occurred"
fi
