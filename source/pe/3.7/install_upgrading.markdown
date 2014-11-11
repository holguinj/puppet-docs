---
layout: default
title: "PE 3.7 » Installing » Upgrading"
subtitle: "Upgrading Puppet Enterprise"
canonical: "/pe/latest/install_upgrading.html"
---


### Upgrading Overview

> **Important**: Before upgrading, please review [Important Information about Upgrades to PE 3.7 and Directory Environments](./install_upgrading_dir_env_notes.html), as some user action is required. Please also review [Upgrading Puppet Enterprise: Notes and Warnings](install_upgrading_notes.html), which includes important information about upgrading to the new node classifier and the new Puppet Server running on the Puppet master.
>
> Currently upgrades to PE 3.7.0 are only supported from the 3.3.x line.
>
> We generally recommend updating your PE deployments in full before upgrading to a new version. 

The Puppet Installer script is used to perform both installations and upgrades. The script will check for a prior version and run as upgrader or installer as needed. You start by [downloading][downloading] and unpacking a tarball with the appropriate version of the PE packages for your system. Then, when you run the `puppet-enterprise-installer` script, the script will check for a prior installation of PE and, if it detects one, will ask if you want to proceed with the upgrade. The installer will then upgrade all the PE components (master, agent, etc.) it finds on the node to version 3.7.

#### Upgrading a Monolithic Installation
If you have a monolithic installation (with the master, PE console, and database components all on the same node), the installer will upgrade each component in the correct order, automatically. 

> **Note**: The new node classifier and role-based access control (RBAC) will be installed as part of the PE console. 

#### Upgrading a Split Installation
If you have a split installation (with the master, PE console, and database components on different nodes), the process involves the following steps, which **must be performed in the following order**:

1. Upgrade the Puppet Master
2. Upgrade PuppetDB
3. Upgrade the PE Console
4. Upgrade Puppet agent nodes

> **Note**: When upgrading to PE 3.7.x, the node classifier and role-based access control (RBAC) will be installed on the PE console node. 


> ![windows logo](./images/windows-logo-small.jpg) To upgrade Windows agents, simply download and run the new MSI package as described in [Installing Windows Agents](./install_windows.html). However, be sure to upgrade your master, console, and database nodes first.

### Downloading PE

If you haven't done so already, you will need a Puppet Enterprise tarball appropriate for your system(s). See the [Installing PE][downloading] section of this guide for more information on accessing Puppet Enterprise tarballs, or go directly to the [download page](http://info.puppetlabs.com/download-pe.html).

[downloading]: ./install_basic.html#downloading-puppet-enterprise

Once downloaded, copy the appropriate tarball to each node you'll be upgrading.

### Running the Upgrade

Before starting the upgrade, all of the components (agents, master, console, etc.) in your current deployment should be correctly configured and communicating with each other, and live management should be up and running with all nodes connected.

> **Important:** All installer commands should be run as `root`.

> **Note**: The upgrader can install a pre-configured version of PostgreSQL (must be version 9.2) along with PuppetDB on the node you select. If you prefer to use a node with an existing instance of PostgreSQL, that instance needs to be manually configured with the correct users and access. This also needs to be done BEFORE starting the upgrade.

#### Step 1: Upgrade the Puppet Master

Start the upgrade by running the `puppet-enterprise-installer` script on the master node. The script will detect any previous versions of PE components and stop any PE services that are currently running. The script will then step through the install script, providing default answers based on the components it has detected on the node (e.g., if the script detects only an agent on a given node, it will provide "No" as the default answer to installing the master component). The upgrader should be able to answer all of the questions based on your current installation except for the hostname and port of the PuppetDB node you prepped before starting the upgrade.

As with installation, the script will also check for any missing dependent vendor packages and offer to install them automatically.

Lastly, the script will summarize the upgrade plan and ask you to go ahead and perform the upgrade. Your answers to the script will be saved as usual in `/etc/puppetlabs/installer/answers.install`.

The upgrade script will run and provide detailed information as to what it installs, what it updates and what it replaces. It will preserve existing certificates and `puppet.conf` files.

#### Step 2: Upgrade PuppetDB

On the node you provisioned for PuppetDB before starting the upgrade, unpack the PE 3.7 tarball and run the `puppet-enterprise-installer` script. 

#### Step 3: Upgrade the Console

On the node serving the console component, unpack the PE 3.7 tarball and run the `puppet-enterprise-installer` script. The installer will detect the version from which you are upgrading and answer as many installer questions as possible based on your existing deployment.

The installer will also ask for the following information:

* The hostname and port number for the PuppetDB node you created in the previous step.
* Database credentials; specifically, the database names, user names, and passwords for the console, role-based access control (RBAC), and PuppetDB databases. These can be found in `/etc/puppetlabs/installer/database_info.install` on the PuppetDB node.

**Important**: If you will be using your own instance of PostgreSQL (as opposed to the instance PE can install) for the console and PuppetDB, it must be version 9.2 or higher.

In addition if you are using an external PostgreSQL instance that is not managed by PE, please note the following: 

1. You will need to create databases for RBAC, activity service, and the node classifier before upgrading.
2. The databases you create need to have the citext extension enabled. 

> **Disabling/Enabling Live Management During an Upgrade**
>
>The status of live management is not managed during an upgrade of PE unless you specifically indicate a change is needed in an answer file. In other words, if your previous version of PE had live management enabled (the PE default), it will remain enabled after you upgrade unless you add or change `q_disable_live_manangement={y|n}` in your answer file. 
>
>Depending on your answer, the `disable_live_management` setting in `/etc/puppetlabs/puppet-dashboard/settings.yml` on the puppet master (or console node in a split install) will be set to either `true` or `false` after the upgrade is complete.
>
>(Note that you can enable/disable Live Management at any time during normal operations by editing the aforementioned `settings.yml` and then running `sudo /etc/init.d/pe-httpd restart`.)

#### Upgrade Agents and Complete the Upgrade

The simplest way to upgrade agents is to upgrade the `pe-agent` package in the repo your package manager (e.g., Satellite) is using. Similarly, if you are using the PE package repo hosted on the master, it will get upgraded when you upgrade the master. You can then [use the agent install script](./install_basic.html#installing-agents-using-pe-package-management) as usual to upgrade your agent.

For nodes running an OS that doesn't support remote package repos (e.g., Windows) you'll need to use the installer script on the PE tarball as you did for the master, etc. On each node with a puppet agent, unpack the PE 3.7 tarball and run the `puppet-enterprise-installer` script. The installer will detect the version from which you are upgrading and answer as many installer questions as possible based on your existing deployment. Note that the agents on your puppet master, PE console, and PuppetDB nodes will have been updated already when you upgraded those nodes. 

PE services should restart automatically after the upgrade. But if you want to check that everything is working correctly, you can run `puppet agent -t` on your agents to ensure that everything is behaving as it was before upgrading. Generally speaking, it's a good idea to run puppet right away after an upgrade to make sure everything is hooked and has the latest configuration.

### Checking For Updates

[Check here][updateslink] to find out the latest maintenance release of Puppet Enterprise. To see the version of PE you are currently using, you can run `puppet --version` on the command line.

{% comment %} This link is the same one as the console's help -> version information link. We only have to change the one to update both. {% endcomment %}

[updateslink]: http://info.puppetlabs.com/download-pe.html

**Note: By default, the puppet master will check for updates whenever the `pe-puppetserver` service restarts.** As part of the check, it passes some basic, anonymous information to Puppet Labs' servers. This behavior can be disabled if need be. The details on what is collected and how to disable checking can be found in one of the [answer file references](./install_mono_answers.html#puppet-master-answers).

* * *


- [Next: Uninstalling](./install_uninstalling.html)
