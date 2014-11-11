---
layout: default
title: "PE 3.7 » Quick Start » DNS"
subtitle: "DNS Quick Start Guide"
canonical: "/pe/latest/quick_start_dns.html"
---

[downloads]: http://info.puppetlabs.com/download-pe.html
[sys_req]: ./install_system_requirements.html
[agent_install]: ./install_agents.html
[install_overview]: ./install_basic.html

Welcome to the Puppet Enterprise DNS Quick Start Guide. This document provides instructions for getting started managing a simple DNS nameserver file with PE. A nameserver ensures that the "human-readable" names you type in your browser (e.g., `google.com`) can be resolved to IP addresses your computers can read.

Sysadmins typically need to manage a nameserver file for internal resources that aren't published in public nameservers. For example, let's say you have several employee-maintained servers in your infrastructure, and the DNS network assigned to those servers use Google's public nameserver located at `8.8.8.8`. However, there are several resources behind your company's firewall that your employees need to access on a regular basis. In this case, you'd build a private nameserver (say at `10.16.22.10`), and then use PE to ensure all the servers in your infrastructure have access to it. 

Following this example, you will use this guide to:

* [write a simple module that contains a class called `resolver` to manage a nameserver file called, `/etc/resolv.conf`](#write-the-resolver-class).
* [use the PE console to add the `resolver` class to your agent nodes](#add-the-resolver-class-in-the-console). 
* [change the contents of the nameserver file to see how PE enforces the desired state you specified in the PE console](#enforce-the-desired-state-of-the-resolver-class).


### Install Puppet Enterprise and the Puppet Enterprise Agent

If you haven't already done so, you'll need to get PE installed. See the [system requirements][sys_req] for supported platforms. 

1. [Download and verify the appropriate tarball][downloads].
2. Refer to the [installation overview][install_overview] to determine how you want to install PE, and then follow the instructions provided.
3. Refer to the [agent installation instructions][agent_install] to determine how you want to install your PE agent(s), and then follow the instructions provided.

>**Tip**: Follow the instructions in the [NTP Quick Start Guide](./quick_start_ntp.html) to have PE ensure time is in sync across your deployment.

>**Note**: You can add the DNS nameserver class to as many agents as needed. For ease of explanation, our console images or instructions may show only one agent node. 

### Write the `resolver` Class

Some modules can be large, complex, and require a significant amount of trial and error, while others, like [PE-supported modules](https://forge.puppetlabs.com/supported), often work "right out of the box". This module will be a very simple module to write; it contains just one class and one template.  

> #### A Quick Note about Modules
>
>The first thing to know is that, by default, the modules you use to manage nodes are located in `/etc/puppetlabs/puppet/modules`---this includes modules installed by PE, those that you download from the Forge, and those you write yourself.
>
>**Note**: PE also installs modules in `/opt/puppet/share/puppet/modules`, but don’t modify anything in this directory or add modules of your own to it.
>
>There are plenty of resources about modules and the creation of modules that you can reference. Check out [Modules and Manifests](./puppet_modules_manifests.html), the [Beginner's Guide to Modules](/guides/module_guides/bgtm.html), and the [Puppet Forge](https://forge.puppetlabs.com/).

Modules are directory trees. For this task, you'll create the following files:

 - `resolver` (the module name)
   - `manifests/`
      - `init.pp` (contains the `resolver` class)
   - `templates/`
      - `resolv.conf.erb` (contains template for `/etc/resolv.conf` template, the contents of which will be populated after you add the class and run PE.)

**To write the `resolver` class**:

1. From the command line on the puppet master, navigate to the modules directory (`cd /etc/puppetlabs/puppet/modules`).
2. Run `mkdir -p resolver/manifests` to create the new module directory and its manifests directory.
3. Use your text editor to create the `resolver/manifests/init.pp` file.
4. Edit the `init.pp` file so it contains the following Puppet code.

        class resolver (
          $nameservers,
        ) {

          file { '/etc/resolv.conf':
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('resolver/resolv.conf.erb'),
          }
        }

5. Save and exit the file.
6. Run `mkdir -p pe_resolver/templates` to create the new module directory and its templates directory.
6. Use your text editor to create the `resolver/templates/resolv.conf.erb` file. 
7. Edit the `resolv.conf.erb` file so that it contains the following ruby code.

        # Resolv.conf generated by Puppet

        <% [@nameservers].flatten.each do |ns| -%>
        nameserver <%= ns %>
        <% end -%>

        # Other values can be added or hard-coded into the template as needed.

8. Save and exit the file. 

> That's it! You've written a module that contains a class that will, once applied, ensure your agent nodes resolve to your internal nameserver. You'll need to wait a short time for the Puppet server to refresh before the classes are available to add to your agent nodes.
>
> Note the following about your new class:
>
> * The class `resolver` ensures the creation of the file `/etc/resolv.conf`. 
> * The content of `/etc/resolv.conf` is modified and managed by the template, `resolv.conf.erb`. You will set this content in the next task using the PE console. 
 
      
### Add the `resolver` Class in the Console

[classification_selector]: ./images/quick/classification_selector.png

For this procedure, you're going to add the `resolver` class to the **default** group. 

The **default** group contains all the nodes in your deployment (including the Puppet master), but you can [create your own group](./console_classes_groups_getting_started.html#creating-new-node-groups) or add the classes to individual nodes, depending on your needs. 

**To add the** `resolver` **class to the default group**:

1. From the console, click __Classification__ in the top navigation bar.

   ![classification selection][classification_selector]

2. From the __Classification page__, select the __default__ group.

3. Click the __Classes__ tab. 
   
4. In the __Class name__ field, begin typing `resolver`, and select it from the autocomplete list.

5. Click __Add class__. 

6. Click __Commit 1 change__.

   **Note**: The `resolver` class now appears in the list of classes for the __default__ group, but it has not yet been configured on your nodes. For that to happen, you need to kick off a puppet run. 
   
7. Navigate to the live management page, and select the __Control Puppet__ tab. 

8. Click the __runonce__ action and then __Run__. This will configure the nodes using the newly-assigned classes. Wait one or two minutes.

> Not done just yet! The `resolver` class now appears in the list of classes for agent1.example.com, but it has not yet been fully configured---you still need to add the nameserver IP address parameter for the `resolver` class to use. You can do this by adding a parameter right in the console. 
     
#### Add the Nameserver IP Address Parameter in the Console

You can add class parameter values to the code in your module, but it’s easier to add those parameters to your classes using the PE console.
  
**To edit the server parameter of the** `resolver` **class**: 

1. From the console, click __Classification__ in the navigation bar.
2. From the __Classification page__, select the __default__ group.
3. Click the __Classes__ tab, and find `resolver` in the list of classes. 
4. From the __parameter__ drop-down menu, choose __nameservers__.
5. In the __Value__ field, enter the nameserver IP address you'd like to use (e.g., `8.8.8.8`).

   **Note**: The grey text that appears as values for some parameters is the default value, which can be either a literal value or a Puppet variable. You can restore this value by selecting __Discard changes__ after you have added the parameter.
   
6. Click __Add parameter__. 
7. Click __Commit 1 change__. 
8. Navigate to the live management page, and select the __Control Puppet__ tab. 
9. Click the __runonce__ action and then __Run__ to trigger a puppet run to have Puppet Enterprise create the new configuration. 
10. Navigate to `/etc/resolv.conf`. This file now contains the contents of the `resolv.conf.erb` template and the nameserver IP address you added in step 4. 

> Success! Puppet Enterprise will now use the nameserver IP address you've specified for that node. 
> 
> #### Viewing Changes with Event Inspector
>
>The PE console event inspector lets you view and research changes ("events"). You can view changes by **class**, **resource**, or **node**. For example, after applying the `resolver` class, you can use event inspector to confirm that changes (or "events") were indeed made to your infrastructure, most notably that the class created `/etc/resolv.conf` and set the contents as specified by the module's template. 
>
>The further you drill down in event inspector, the more detail you'll receive. If there had been a problem applying the `resolver` class, this information would tell you exactly where that problem occurred or which piece of code you need to fix. 
>
>In the upper right corner of the screen is a link to a run report, which contains information about the changes made during puppet runs, including logs and metrics about the run. Visit the [reports page](./console_reports.html#reading-reports) for more info.
>
>For more information about using the PE console event inspector, check out the [event inspector docs](./console_event_inspector). 
 
### Enforce the Desired State of the `resolver` Class

Finally, let's take a look at how PE will ensure the desired state of the `resolver` class on your agent nodes. In the previous task, you set the nameserver IP address. Now imagine a scenario where a member of your team changes the contents of `/etc/resolv.conf` to use a different nameserver and can no longer access any internal resources. 

1. On any agent node to which you applied the `resolv.conf` class, edit `/etc/resolv.conf` to be any  nameserver IP address other than the one you desire to use. 
2. Save and exit the file.
2. From the console, navigate to the live management page, and select the __Control Puppet__ tab.
3. Click the __runonce__ action and then __Run__ to trigger a puppet run. 
8. Navigate to `/etc/resolv.conf`, and notice that PE has enforced the desired state you specified for the nameserver IP address. 

> That's it --- PE has enforced the desired state of your agent node!
>
> And remember, as indicated above, you review the changes to the class or node using event inspector. 

### Other Resources

For more information about working with Puppet Enterprise and DNS, check out our [Dealing with Name Resolution Issues](http://puppetlabs.com/blog/resolving-dns-issues) blog post. 

Puppet Labs offers many opportunities for learning and training, from formal certification courses to guided online lessons. We've noted a few below; head over to the [learning Puppet page](https://puppetlabs.com/learn) to discover more.

* [Learning Puppet](http://docs.puppetlabs.com/learning/) is a series of exercises on various core topics about deploying and using PE. 
* The Puppet Labs workshop contains a series of self-paced, online lessons that cover a variety of topics on Puppet basics. You can sign up at the [learning page](https://puppetlabs.com/learn).


