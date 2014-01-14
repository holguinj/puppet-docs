---
title: "Using the Puppet Labs Package Repositories"
layout: default
nav: puppet_general.html
---


Puppet Labs maintains official package repositories for several of the more popular Linux distributions. These repos contain the latest available packages for Puppet, Facter, PuppetDB, Puppet Dashboard, MCollective, and several prerequisites and add-ons for Puppet Labs products.

We also maintain repositories for Puppet Enterprise 2.8.x users. These repos contain additional PE components, as well as modified packages for tools like PuppetDB which will integrate more smoothly with PE's namespaced installation layout. Note these *only* apply to users of PE 2.8. In PE 3.x, PuppetDB and other components are already integrated.

This page explains how to enable these repositories on all of the supported operating systems.

Our repositories will be maintained for the life of the corresponding operating system and available for three months after their end of life date. So if an operating system goes end of life on July 15, our repositories for that operating system will still be available until October 15.

Open Source Repositories
-----

Use these repositories to install open source releases of Puppet, Facter, MCollective, PuppetDB, and more. After enabling the repo, [follow the instructions for installing Puppet](./installation.html).

### For Red Hat Enterprise Linux and Derivatives

The [yum.puppetlabs.com](https://yum.puppetlabs.com) repository supports the following versions of Red Hat Enterprise Linux and distributions based on it:

{% include platforms_redhat_like.markdown %}

Enabling this repository will let you install Puppet in Enterprise Linux 5 without requiring any other external repositories like EPEL. For Enterprise Linux 6, you will need to [enable the Optional Channel](https://access.redhat.com/site/documentation/en-US/OpenShift_Enterprise/1/html/Client_Tools_Installation_Guide/Installing_Using_the_Red_Hat_Enterprise_Linux_Optional_Channel.html) for the rubygems dependency.

To enable the repository, run the command below that corresponds to your OS version and architecture:

#### Enterprise Linux 5

##### i386

    $ sudo rpm -ivh https://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-7.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum.puppetlabs.com/el/5/products/x86_64/puppetlabs-release-5-7.noarch.rpm

#### Enterprise Linux 6

##### i386

    $ sudo rpm -ivh https://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm

### For Debian and Ubuntu

The [apt.puppetlabs.com](https://apt.puppetlabs.com) repository supports the following OS versions:

{% include platforms_debian_like.markdown %}

To enable the repository:

1. Download the "puppetlabs-release" package for your OS version.
    * You can see a full list of these packages on the front page of <https://apt.puppetlabs.com/>. They are all named `puppetlabs-release-<CODE NAME>.deb`. (For Ubuntu releases, the code name is the adjective, not the animal.)
    * Architecture is handled automatically; there is only one package per OS version.
2. Install the package by running `dpkg -i <PACKAGE NAME>`.
3. Run `apt-get update` to get the new list of available packages.

For example, to enable the repository for Ubuntu 12.04 Precise Pangolin:

    $ wget https://apt.puppetlabs.com/puppetlabs-release-precise.deb
    $ sudo dpkg -i puppetlabs-release-precise.deb
    $ sudo apt-get update

### For Fedora

The [yum.puppetlabs.com](https://yum.puppetlabs.com) repository supports the following Fedora versions:

{% include platforms_fedora.markdown %}

To enable the repository, run the command below that corresponds to your OS version and architecture:

#### Fedora 17

##### i386

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f17/products/i386/puppetlabs-release-17-7.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f17/products/x86_64/puppetlabs-release-17-7.noarch.rpm

#### Fedora 18

##### i386

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f18/products/i386/puppetlabs-release-18-7.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f18/products/x86_64/puppetlabs-release-18-7.noarch.rpm

#### Fedora 19

##### i386

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f19/products/i386/puppetlabs-release-19-2.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum.puppetlabs.com/fedora/f19/products/x86_64/puppetlabs-release-19-2.noarch.rpm

Enabling the Prerelease Repos
-----

Our open source repository packages also install a disabled prerelease repo, which contains release candidate versions of all Puppet Labs products. Enable this if you wish to test upcoming versions early, or if you urgently need a bug fix that has not gone into a final release yet.

### On Debian and Ubuntu

After installing the repos, open your `/etc/apt/sources.list.d/puppetlabs.list` file for editing. Locate and uncomment the line that begins with `deb` and ends with `devel`:

    # Puppetlabs devel (uncomment to activate)
    deb http://apt.puppetlabs.com precise devel
    # deb-src http://apt.puppetlabs.com precise devel

To disable the prerelease repo, re-comment the line.

### On Fedora, RHEL, and Derivatives

After installing the repos, open your `/etc/yum.repos.d/puppetlabs.repo` file for editing. Locate the `[puppetlabs-devel]` stanza, and change the value of the `enabled` key from `0` to `1`:

    [puppetlabs-devel]
    name=Puppet Labs Devel <%= @dist.capitalize -%> <%= @version -%> - $basearch
    baseurl=http://yum.puppetlabs.com/<%= @dist.downcase -%>/<%= @codename -%>/devel/$basearch
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
    enabled=1
    gpgcheck=1

To disable the prerelease repo, change the value back to `0`.

Puppet Enterprise 2.8 Repositories
-----

Use these repositories to install PE-compatible versions of PuppetDB and the Ruby development headers. **These repositories should only be used with Puppet Enterprise 2.8 and earlier;** PE 3 includes PuppetDB and the Ruby dev libraries by default.

### For Red Hat Enterprise Linux and Derivatives

The [yum-enterprise.puppetlabs.com](https://yum-enterprise.puppetlabs.com) repository supports versions 5 and 6 of Red Hat Enterprise Linux and distributions based on it, including but not limited to CentOS, Scientific Linux, and Ascendos. It contains additional components and add-ons compatible with Puppet Enterprise's installation layout.

To enable the repository, run the command below that corresponds to your OS version:

#### Enterprise Linux 5

##### i386

    $ sudo rpm -ivh https://yum-enterprise.puppetlabs.com/el/5/extras/i386/puppetlabs-enterprise-release-extras-5-2.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum-enterprise.puppetlabs.com/el/5/extras/x86_64/puppetlabs-enterprise-release-extras-5-2.noarch.rpm

#### Enterprise Linux 6

##### i386

    $ sudo rpm -ivh https://yum-enterprise.puppetlabs.com/el/6/extras/i386/puppetlabs-enterprise-release-extras-6-2.noarch.rpm

##### x86_64

    $ sudo rpm -ivh https://yum-enterprise.puppetlabs.com/el/6/extras/x86_64/puppetlabs-enterprise-release-extras-6-2.noarch.rpm

### For Debian and Ubuntu

The [apt-enterprise.puppetlabs.com](https://apt-enterprise.puppetlabs.com) repository supports Debian 6 ("Squeeze"), Ubuntu 10.04 LTS, and Ubuntu 12.04 LTS.

To enable the repository, run the commands below:

    $ wget http://apt-enterprise.puppetlabs.com/puppetlabs-enterprise-release-extras_1.0-2_all.deb
    $ sudo dpkg -i puppetlabs-enterprise-release-extras_1.0-2_all.deb
    $ sudo apt-get update

