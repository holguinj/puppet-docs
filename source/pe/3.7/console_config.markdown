---
layout: default
title: "PE 3.7 » Console »  Configuration"
subtitle: "Configuring & Tuning the Console & Databases"
canonical: "/pe/latest/console_config.html"
---

Configuring Console Authentication
-----

### Changing Session Duration

If you wish to change the duration of a user's session before they have to re-authenticate, add a new file to the `/etc/puppetlabs/console-services/conf.d` directory. The file name is arbitrary but the file format is [HOCON](https://github.com/typesafehub/config). The contents need to have an rbac hash with the desired session timeout value. The default is 1200 (20 minutes).

    rbac: { session-timeout: 45 }

Then restart pe-console-services (`sudo service pe-console-services restart`)

Configuring the Console to Use a Custom SSL Certificate
-------

Full instructions are available [here](./custom_console_cert.html).


Tuning the PostgreSQL Buffer Pool Size
-----

If you are experiencing performance issues or instability with the console, you may need to adjust the buffer memory settings for PostgreSQL. The most important PostgreSQL memory settings for PE are `shared_buffers` and `work_mem`.  Generally speaking, you should allocate about 25% of your hardware's RAM to `shared_buffers`. If you have a large and/or complex deployment you will probably need to increase `work_mem` from the default of 1mb. For more detail, see in the [PostgreSQL documentation](http://www.postgresql.org/docs/9.2/static/runtime-config-resource.html).

After changing any of these settings, you should restart the PostgreSQL server:

    $ sudo /etc/init.d/pe-postgresql restart


Changing the Console's Port
-----

By default, a new installation of PE will serve the console on the default SSL port, 443. If you wish to change the port the console is available on:

1. Visit *Classification*
2. Select the PE Console node group.
3. In the Classes tab, find the `puppet_enterprise::profile::console Class`.
4. Add a new value for the `console_ssl_listen_port` parameter.
5. Trigger a puppet run.

The console should now be available on the port you provided.

Disabling Update Checking
-----

When the console's web server (`pe-httpd`) starts or restarts, it checks for updates. To get the correct update info, the server will pass some basic, anonymous info to Puppet Labs' servers. Specifically, it will transmit:

* the IP address of the client
* the type and version of the client's OS
* the installed version of PE

If you wish to disable update checks (e.g. if your company policy forbids transmitting this information), you will need to add the following line to the `/etc/puppetlabs/installer/answers.install` file:

    q_pe_check_for_updates=n

Keep in mind that if you delete the `/etc/puppetlabs/installer/answers.install` file, update checking will resume.


* * *

- [Next: Puppet Core Overview ](./puppet_overview.html)
