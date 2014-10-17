# intro

This document is intended to capture the orchestration requirements for our current Openstack installation.

There are two main motivations for writing this document:

1. Our overall orchestration workflow is getting very complicated. It makes sense to document it to ensure
that anyone from the team can understand how it works.

2. The workflow is complicated and not as well performing as it could be. This document is intended to
capture those issues along with recommendations for how it can be improved.

# Configuration Orchestration

## Consul

Orchestration is currently managed by both consul and etcd (although in the future, we will be eliminating
etcd in favor of consul for everything)

Consul works as follows:

  * The following Puppet Defined resource `rjil::jiocloud::consul::service` is used to define a service in consul.
  * Each service registers its ip address as an A record for the address: `<service_name>.service.consul`
  * Each service registers its hostname: <hostmame>.node.consul and registers that as a SRV record for `<service_name>.service.consul`

### using DNS

Each agent uses DNS to understand what services are available. There are two ways in which Puppet needs to interact with DNS.

1. block until an address is resolvable
2. block until we can retrieve registered A records or SRV records from an address.

### Puppet design and implications

#### Puppet design

Due to the design of Puppet, these two use cases are implemented in ways that are fundamentally different. The reason that these
two cases are different is due to the distinction in Puppet between compile time versus run time actions.

1. compile time - Puppet goes through a separate process of compiling the catalog that will be used to apply the
   desired configuration state of each agent. During compile time, the following things occur:

* classes are evaluated
* hiera variables are bound
* conditional logic is evaluated
* functions are run
* variables are assigned to resource attributes

This phase processes Puppet manifests, functions, and hiera.

2. run time - during Run time, a graph of resources is applied to the system. Most of the logic that is performed
   during these steps is contained within the actual ruby providers.

#### Puppet orchestration integration tooling

We have implemented the following tools to be used in combination with consul.
  * rjil::service\_blocker - a type that blocks until an A record is registered for an address. It is configured to tell it
    now many times to retry and how long to sleep between each attempt. This check is performed at run-time and requires that
    the hostname to lookup is known ahead of time and that only that hostname is being used to determine attribute values for
    a resource.
  * service\_discovery\_dns - A function that performs a DNS SRV lookup, and returns either discovered ips, hostname, or a hash
    or both. This method is used in cases where information used to populate resource attributes needs to be determined
    dynamically.

#### Implications

The way that Puppet is designed has several implications to the design of our system. In order to achieve the
best performance, it is better to block during resource execution (and run-time) because you can set dependencies
on which resources can be applied in parallel by indicating those resources should be applied before the service\_blocker.
This means that many more resources can be applied in parallel. For example, it would be easy to  use Puppet
dependencies to ensure that the service blocker never happened before any packages are installed.

However, since variable substitution occurs during compile time, anything that relies on using the static DNS address,
(ie: by using the service\_discovery\_dns function) must be performed during compile time. This means that the entire
catalog application is blocked until this data becomes available.

# Openstack Dependencies

This section is intended to document all of the cross host dependencies of our current Openstack architecture,
and emphasize the performance implications of each step.

1. All machines block for the etcd/consul server to come up.

2. Currently, the stmonleader, contrail controller, and haproxy machine can all start applying configuration immediately.

** The contrail node can currently install itself successfully as soon as consul it up. This is only because it doesn't
   actually install the service correctly.

** stmonleader can install itself as soon as consul is ready. It may have to run twice to configure OSD's (which we may do
   in testing, but not in prod)

** haproxy - can install itself, but it does not configure the balance members until the controller nodes are running.


It is worth noting that two of these roles will need to reapply configuration when the rest of the services come online.

* haproxy needs all addresses for all controllers it adds them as pool members
* stmonleader needs to have all it's mons registered as well as an OSD number that matches num replicas.

3. Once stmon.service.consul is registered in consul, stmon, ocdb, and oc can start compiling. These machines have
   not performed any configuration at all at this point. At the same time, stmonleader might be adding it's ods (which
   takes two runs)

4. oc will start compiling, but it blocks until the database is resolvable, once that is resolvable, it continues. At the same
  time stmon's are rerunning Puppet to set up their osd drives.

5. once oc and ocdb are up, haproxy registers poolmembers.

# Diagram

The below diagram is intended to keep track of what services are dependent on other services
for configuration.

                  +--------+
                  | consul |
                  +------+-+---------------+--------------+
                         |                 |              |
                         |                 |              |
                         |                 |              |
                         |                 |              |
                 +-------v-----+     +-----v----+   +-----v----+
                 | stmonleader |     | contrail |   |  haproxy |
            +----+-----------+-+     +----------+   +----------+
            |                |
            |                |
            |                |
        +---v---+        +---v--+
        | stmon |        | ocdb |
        +-------+        +----+-+
        |                     |
        |                     |
        |                     |
    +---v---+               +-v--+
    | stmon |               | oc |
    +-------+               +----+-----+
                                       |
                                       |
                                       |
                                       |
                                  +----v----+
                                  | haproxy |
                                  +---------+


# known issues

1. the system still does not properly distinguish between addresses of services that will be running vs.
   addresses of things that will be running.

For example: glance, cannot actually be a functional service until keystone has been been registered as
a service and it's address propagated to the load balancer. However, the load balancer cannot be properly
verified until glance has registered (maybe this is actually not a problem...)

2. We have not yet implemented service watching. Currently, it is possible that all occurrences of a certain
   service are not property configured. This is because Puppet just continues to run until it can validate a
   service as functional. The correct way to resolve this is to ensure that you can watch a service, and ensure
   that Puppet runs to reconfigure things when service addresses change (this would currently apply to zeromq,
   ceph, and haproxy.)

3. Failing on compile time adds significant wall-clock time to tests, especially because multiple nodes have to
   be installed completely in serial.

4. The system doesn't really know when it is done running Puppet. We need to somehow understand what the desired
   cardinality is for a service. Perhaps this should be configured as a validation check (ie: haproxy is only
   validated when it has the same number of members as there should be configured services.)
