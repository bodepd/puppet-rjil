[![Build Status](https://travis-ci.org/JioCloud/puppet-rjil.svg?branch=master)](https://travis-ci.org/JioCloud/puppet-rjil)

ST!!!

# What puppet-rjil?

This project is the top level project where most of the deployment coding
for jiocloud happens.

It is composed of the following:

* ./manifests/
  composition Puppet manifests for building jiocloud
* hiera/hiera.yaml
  hiera configuration file that should be used for jiocloud
* hiera/data/
  directory where default hiera data should go. Pretty much anything that
  doesn't contain lookups or secrets should be stored here.
* Vagrantfile
  A Vagrantfile that can be used for faster deployments and iterative
  development.
  NOTE: Vagrant has it's own hiera env data in `./hiera/data/env/vagrant.yaml`:
* Puppetfile
  List of all puppet modules that need to be installed as dependencies.
* ./build\_scripts/deploy.sh - Script that performs deployment of jiocloud.
* ./files/maybe-upgrade.sh - script that actually runs Puppet to perform
  deployments on provisioned machines (when not using vagrant)

# using vagrant for development

## installing vagrant

[Install Virtualbox](http://www.virtualbox.org/manual/ch01.html#intro-installing)

[Install vagrant](https://docs.vagrantup.com/v2/installation/)

## Using vagrant

Vagrant makes it easier to perform iterative development on modules.

First, you need to make sure that your Puppet module dependencies are
installed:

````
gem install librarian-puppet-simple
# from root level of this repo
librarian-puppet install
````

To get a list of support roles that can be booted by vagrant, run:

````
vagrant status
````

To boot your desired role in vagrant
````
vagrant up <role>
````

To re-run Puppet provisioning (for interactive development of modules)

````
vagrant provision <role>
````

## Adding new roles to vagrant

1. Ensure that the role exists in site.pp as a node declaration

````
node /^somerole/ {
  include somerole
}
````

2. Ensure the node is defined in Vagrant

At the top of the Vagrantfile, you need to add an entry for the node:

the entry maps the hostname of the machine to be provisioned:
````
:openstackclient => '15',
````

This will boot a machine of hostname openstackclient with the following ip addresses:
* 10.22.3.15
* 10.22.4.15

3. Add relevant hiera data. Vagrant has it's own hiera data file where you
   can add hard-coded addresses.

````
./hiera/data/env/vagrant.yaml
````

# Doing multi-node deployments into an openstack cloud

This repo also contains the following script that can deploy multiple nodes
using the exact same process that the build pipeline will use.

````
./build\_scripts/deploy.sh
````
## Building custom deployments

At a high level, the following must be done to get a build up-and-going.

1. Define the build you need to deploy (what roles and how many)

2. Ensure that Puppet configuration exists to support this deployment

3. Ensure the relevant hiera data exists in the hierarchy

4. Use the build script

5. Debug the build process to follow a build's progress

## Defining deployment data

The build script is driven by a set of data that describes the machines that
need to be configured.

These build scripts can be found in the environment directory.
The filename should be of the form:

````
./environment/cloud.<env>.yaml
````

where env is an argument passed into the build script.

The most robust multi-node example at the time this README was written can be
found at:
````
./environment/cloud.dan.yaml
````

### file contents

This file should contain the top level key `resources`.

Here resources should be listed. Where the names of these
resource should match a node expression.

For example, if the following resources are specified:

````
resources:
  etcd:
    number: 1
    ...
  apache:
    number: 2
```

It will result in hostnames that are prefixed with the following strings:
* etcd1
* apache1
* apache2

A set of matching nodes in site.pp might look like:

````
node /^etcd\d+/ {

}
node /^apache\d+/ {

}
````

Those nodes in term should whatever classes are required to configure those
roles

## Populating hiera data

There are two types of hiera data that need to be populated.

1. regular hiera data for configuring roles.
2. hiera data that support cross host dependencies

### supporting cross host dependencies

Cross host dependencies are supported by the following process:

1. Each profile can register itself as providing a certain service by
   using the rjil::profile puppet defined resource type.

The following example shows how the rjil::keystone class registers itself
as providing the keystone service

````
rjil::profile { 'keystone': }
````

this will just write the line `keystone` into the file /var/lib/puppet/profile_list.txt.

2. Once has a service has been successfully configured, maybe-upgrade.sh runs
the following command:

````
python -m jiocloud.orchestrate --discovery_token=$discovery_token publish_service
````

This command will publish the host (along with it's addresses) as providing the services
listed in that file.

For example, if a host had the following contents in /var/lib/puppet/profile_list.txt:

````
db
keystone
````

Running the above command results in the following keys in etcd

````
\#etcd> etcdctl ls /available\_services
/available_services/db
/available_servies/keystone
````

These directories contain keys that list all addresses and interfaces
for each role.
````
\#etcd> etcdctl get /available\_services/db/db1-testtest-180914130103
{"lo": "127.0.0.1", "eth1": "10.208.137.211", "eth0": "192.237.177.237"}
````

3. All discoverable service information is written into hiera before each Puppet run

All of these entries are written into hiera before each puppet apply command
with the following command:

````
python -m jiocloud.orchestrate --discovery_token=$discovery_token cache_services
````

This populates all data about discoverable services to hiera:

````
/etc/puppet/hiera/data/services.yaml
````

For each interface discovered for each role, it adds an entry:

````
services::<role>::<interface>: [host_addresses]
````

For example, if two hosts were found to provide the keystone role, and each
had two interfaces, the output might look like this:

````
services::keystone::eth0: [192.237.177.253, 192.237.165.123]
services::keystone::eth1: [10.208.138.7, 10.208.132.47]
````

4. End user writes custom hierarchies that know how to look that data up.

It is up to the person defining the deployment process to specify how
parameters shoud be retrieved from services.yaml

In order to lookup the correct data, you should know the following:

the hiera data value that you need to populate:

the name of the published services that it needs to get data from:

the interface that is hosting the address that you need for that service

NOTE: this definitely makes an assumption that network address types are always
on the same interface acorss hosts. This is a design constraint of this system.

For example:

Since, I deploy using the env=dan. I would put my mapping rules in:

````
./hiera/data/env/dan.yaml
````

NOTE: you need to run the build script with the correct env passed.

If I wanted the class parameter `rjil::haproxy::openstack::keystone_ips`
to be equal to the value of all addresses on eth0 of all published machines
providing the keystone role, I could do the following:

````
rjil::haproxy::openstack::keystone_ips: "%{lookup_array('services::keystone::eth0')}"
````

NOTE: If lookup_array gets no results back, it will cause Puppet to fail. This
failure is a requirement for this deployment process to work b/c failures cause
Puppet to keep retrying.

## Running the build script

To run the build script, invoke

````
bash -x build\_scripts/deploy.sh
````

The script can be configured using the following environment variables:

### BUILD\_NUMBER (required)

Used to attach a unique identifier to all vms created as a part of a test deployment.
This is useful for distinguishing between separate sets of machines that may be
on the same network.

If you are going to be performing multiple deployments for testing purposes, it is recommended
to use a timestamp to make the build number unique per invocation:

````
export BUILD\_NUMBER=`date +"%d%m%y%H%M%S"`;
````

This build number is appended to all of the hostname prefixes of the provisioned machines.

### env (required)

The environment indicator.

````
export env=dan
````

This is used to determine the file that specifies what machines
should exist for a specific deployment.
It refers to the file environment/cloud.${env}.yaml.

It is also used to pull env specific hiera data from ./hiera/data/env/${env}.yaml

### KEY\_NAME (required)

The name of the keypair that will used assigned to the VM.

````
export KEY\_NAME=openstack\_ssh\_key
````

### env\_file (optional)

File that contains the following environment variables used to configuration access
and authentication against your openstack environment.

This argument is optional provided that you manually provide those environment variables.

````
export env\_file=~/credentials.sh
````

### timeout (optional)

Name of the command that provides the timeout capability. You should only even have to
set this if you are using the script from a Mac (or other Unix system).

````
export timeout\_command=gtimeout
````

### puppet\_modules\_source (optional)

Location of source repository for puppet-rjil. This is required if you want to test against
a branch instead of against the puppet-rjil contents that are packaged. This is very
handy for pre-validating some configuration before running tests.

````
export puppet\_modules\_source\_repo=https://github.com/bodepd/puppet-rjil
````

### puppet\_modules\_source\_branch (optional, only makes sense together with puppet\_modules\_source)

Branch that should be used from the provided puppet-rjil repo.

````
export puppet\_modules\_source\_branch=origin/deploy\_script
````

### ssh\_user

User to that build process should use to ssh into etcd server.

````
ssh\_user=ubuntu
````

## Example of a full invocation

This is what I used for testing:

````
export BUILD\_NUMBER=test\_`date +"%d%m%y%H%M%S"`;export env=dan;export KEY\_NAME=openstack\_ssh\_key; export env\_file=~/credentials.sh;export timeout\_command=gtimeout; export puppet\_modules\_source\_repo=https://github.com/bodepd/puppet-rjil;export puppet\_modules\_source\_branch=origin/deploy\_script;export ssh\_user=ubuntu;bash -x build\_scripts/deploy.sh
````

## dependencies on mac

The first time this script runs (or when it needs to update the version of jiocloud
install), there are a few deps that need to be manually installed on Mac.

````
brew install python
pip install virtualenv
brew install libffi
brew install libyaml
brew install coreutils
alias timeout=gtimeout
````


It is possible that you will also have to manually update the include path to ensure
that libffi is available:

````
export CFLAGS="-I/usr/local/opt/libffi/lib/libffi-3.0.13/include/"
````
