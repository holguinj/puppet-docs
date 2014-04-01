---
title: "Classifier 0.2: Installation and Setup"
layout: default
---

# Classifier Installation and Setup

## Overview
Before you can get the Classifier up and running, you'll need to install Puppet 3.5.0 or greater and PostgreSQL 9.2 or greater. Note that, like the Classifier itself, Puppet 3.5.0 is still pre-release software and is not yet recommended for use in production.

The Classifier service doesn't need to be run on the same node as the puppet master, but it does need to run on a node that's managed by the puppet master and has the appropriate certificates present.

## Install and Configure PostgreSQL
We recommend installing PostgreSQL by using the [puppetlabs-postgresql module](https://forge.puppetlabs.com/puppetlabs/postgresql). If you already have a working PostgreSQL server that's managed by puppet, just add the parts that are missing to the relevant manifests. Otherwise, install the module with `sudo puppet module install puppetlabs-postgresql` and apply the following puppet code:

{% highlight ruby %}
   class {'postgresql::globals':
      manage_package_repo => true,
      version             => '9.2',
    } ->

   class {'postgresql::server': } ->
{% endhighlight %}

Feel free to add parameters to the `postgresql::server` declaration, although you should be aware that changing certain settings (such as the address and port of the postgresql server) may make it difficult or impossible for the Classifier to connect.

You're also going to need to create a database and a role for the Classifier to use, which you can do with another bit of puppet code. You'll want to change `kla$$ifier` to something more secure:

{% highlight ruby %}
  $classifier_password = 'kla$$ifier'  #change this

  postgresql::server::role { 'classifier':
    password_hash => postgresql_password('classifier', $classifier_password),
  } ->
  
  postgresql::server::db { 'classifier':
    user     => 'classifier',
    password => postgresql_password('classifier', $classifier_password),
  }
{% endhighlight %}

The last thing you need to do is make sure that the `classifier` role can connect to the server using password authentication:

{% highlight ruby %}
  postgresql::server::pg_hba_rule {'Allow the classifier role to access its database':
    type        => 'host',
    database    => 'classifier',
    user        => 'classifier',
    address     => '127.0.0.1/32',
    description => 'Open up postgresql for access to classifier database',
    auth_method => 'password',
  }
{% endhighlight %}

## Install and Configure the Classifier

### Installing the Classifier
Because the Classifier is not yet officially released, you'll need to follow the directions to [add the prerelease repositories](/guides/puppetlabs_package_repositories.html#enabling-the-prerelease-repos). After that, install both the `classifier` and `classifier-terminus` packages with your distribution's package manager.

### Importing Puppet Certificates
Because the Classifier need to communicate securely with the puppet master, you'll have to give it a copy of the puppet agent host certificate, host private key, and CA certificate. Execute the following shell commands to find and copy the certificates:

{% highlight bash %}
CERT=`puppet agent --configprint hostcert`
KEY=`puppet agent --configprint hostprivkey`
CACERT=`puppet agent --configprint localcacert`

SSLDIR="/etc/classifier/ssl"
cp $CERT $SSLDIR/cert.pem
cp $KEY $SSLDIR/key.pem
cp $CACERT $SSLDIR/ca.pem
{% endhighlight %}

### Editing `config.ini`
The Classifier's main configuration file is located at `/etc/classifier/classifier.ini`. Before you can do anything useful with the Classifier, you'll need to edit that file to point to the classifier database, certificate files, and puppet master:

{% highlight ini %}
# /etc/classifier/classifier.ini complete example
[webserver]
host = 0.0.0.0
port = 1261
ssl-host = 0.0.0.0
ssl-port = 1262

ssl-cert = /etc/classifier/ssl/cert.pem
ssl-key = /etc/classifier/ssl/key.pem
ssl-ca-cert = /etc/classifier/ssl/ca.pem

[classifier]
url-prefix =
# make sure that the following line points to your puppet master
puppet-master = https://master:8140

[database]
dbname = classifier
user = classifier
# add the password you set above:
password = 
{% endhighlight %}

With that done, the Classifier will be ready to go. You should (re)start the `classifier` service and watch the log file (`/var/log/classifier/classifier-daemon.log`) to make sure it starts properly.

## Configure the Puppet Terminus
The Classifier should be running and connected to its own database at this point, so the only thing left is to make the puppet master aware of it. The steps in this section should all be carried out on the puppet master.

First, create a new `classifier.yaml` file in puppet's confdir (`/etc/puppet` by default) to tell puppet where to reach the Classifier service:

{% highlight yaml %}
---
server: classifier_hostname #must match that node's certificate
port: 1262
{% endhighlight %}

Next, you'll need to edit puppet's `auth.conf` file (also in confdir) to allow the Classifier to retrieve data from the master. Add the following block anywhere in the file:

{% highlight ini %}
path /resource_type
method find, search
auth yes
allow *
{% endhighlight %}

Finally, run `sudo puppet config set node_terminus classifier` to make the master rely on the Classifier for classification, then restart the `puppetmaster` service. Note that from this point on, the puppet master will refuse to compile any catalogs if it can't reach the Classifier. If you need to revert this setting to default, use `sudo puppet config set node_terminus plain`.

## Next Steps
At this point, your Classifier is running and enabled, but it won't be of any use until you add some classes and groups. See the [Classifier API reference](api_reference.html) to get a detailed look at how this is done or continue on to the [Classification example](classification_example.html) for a guided walkthrough of the process of adding a new class and group.
