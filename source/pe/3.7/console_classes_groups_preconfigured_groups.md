---
layout: default
title: "PE 3.7 » Console » Grouping and Classifying Nodes"
subtitle: "Preconfigured Node Groups"
canonical: "/pe/latest/console_classes_groups_preconfigured_groups.html"
---

[puppet]: ./puppet_overview.html
[puppet_assign]: ./puppet_assign_configurations.html
[lang_classes]: /puppet/3.7/reference/lang_classes.html
[learn]: /learning/
[forge]: http://forge.puppetlabs.com
[modules]: /puppet/3.7/reference/modules_fundamentals.html
[topscope]: /puppet/3.7/reference/lang_scope.html#top-scope
[environment]: /guides/environment.html

Puppet Enterprise automatically creates a number of special node groups for managing your deployment. In a new install, these node groups will come with some default classes. If you're upgrading, only the **MCollective** node group will come with classes. 

**Note:** In general, you should not remove these node groups or delete classes from them.  

The default settings for each node group are shown below. 

## The Default Node Group

### Role
This node group is used for assigning classes to all nodes. For example, you can use it to assign the `ntp` class to all nodes.

### Classes
No default classes.

> **Note:** If you set classes in the **default** group, you will not be able to set the agent-specified environment until you remove the classes from the **default** group.

### Matching nodes
All nodes.

### Notes
* You can add and remove classes, parameters, and variables.
* You cannot modify the rules.

## The PE Infrastructure Node Group

### Role
This node group is the parent to all of the node groups listed below (all preconfigured node groups except for the **default** node group). It holds shared data that member nodes in child node groups need to know. This includes the hostnames and ports of  various services (such as master and PuppetDB) and database info (except for passwords).

### Classes
* `puppet_enterprise` (sets the default parameters for child node groups)

> **Note:** If you are upgrading, you will need to add the following parameters to the `puppet_enterprise` class:
>
> * `mcollective_middleware_hosts = ["<YOUR HOST>"]`
> * `database_host = "<YOUR HOST>"`
> * `puppetdb_host = "<YOUR HOST>"`
> * `database_port = "<YOUR PORT NUMBER>"`
> * `database_ssl = true` (Set to `true` if you're using the PE-installed postgres, and `false` if you're using your own postgres.)
> * `puppet_master_host = "<YOUR HOST>"`
> * `certificate_authority_host = "<YOUR HOST>"`
> * `console_port =	"<YOUR PORT NUMBER>"`
> * `puppetdb_database_name = "pe-puppetdb"`
> * `puppetdb_database_user = "pe-puppetdb"`
> * `puppetdb_port = "<YOUR PORT NUMBER>"`
> * `console_host =	"<YOUR HOST>"`

### Matching Nodes
There are no nodes pinned to this node group.

## The MCollective Node Group

### Role
This node group is used to enable PE's [orchestration engine](./orchestration_overview.html) on all matching nodes.

### Classes
* `puppet_enterprise::profile::mcollective::agent` (manages the MCollective server)

### Matching Nodes
All nodes.

### Notes
* You may have some nodes, such as non-root nodes or network devices, that **should not** have orchestration enabled. You can create a rule in this node group to exclude these nodes from orchestration. 

## The PE Master Node Group

### Role
This node group is used to manage Puppet masters and [add additional compile masters](./install_multimaster.html#step-3-classify-the-new-puppet-master-node).

### Classes
* `puppet_enterprise::profile::master` (manages the master service)
* `puppet_enterprise::profile::mcollective::peadmin` (manages the peadmin MCollective client)
* `puppet_enterprise::profile::master::mcollective` (manages keys used by MCollective)

### Matching Nodes
The master node is pinned to this node group.

## The PE PuppetDB Node Group

### Role
This node group is used to manage the database service.

### Classes
* `puppet_enterprise::profile::puppetdb` (manages the PuppetDB service)

### Matching Nodes
The PuppetDB server node is pinned to this node group.

### Notes
* You should *not* add additional nodes to this node group.

## The PE Console Node Group

### Role
This node group is used to manage the console. 

### Classes
* `puppet_enterprise::profile::console` (manages the console, node classifier and RBAC)
* `puppet_enterprise::profile::mcollective::console` (manages the Puppet dashboard MCollective client used by live management)
* `pe_console_prune` (manages a cron job to periodically prune the console reports database)
* `puppet_enterprise::license` (manages the PE license file for the status indicator)

### Matching Nodes
The console server node is pinned to this node group.

### Notes
* You should *not* add additional nodes to this node group.

## The PE Certificate Authority Node Group

### Role
This node group is used to manage the certificate authority.

### Classes
* `puppet_enterprise::profile::certificate_authority` (manages the certificate authority on the first master node)

### Matching Nodes
The master node is pinned to this node group.

### Notes
You should *not* add additional nodes to this node group.

## The PE ActiveMQ Broker Node Group

### Role
This node group is used to manage the ActiveMQ broker and [add additional ActiveMQ brokers](./install_add_activemq.html#step-3-create-the-activemq-hub-group).

### Classes
* `puppet_enterprise::profile::amq::broker` (manages the ActiveMQ MCollective broker)

### Matching Nodes
The master node is pinned to this node group.


* * *

- [Next: How Does Inheritance Work?](./console_classes_groups_inheritance.html)