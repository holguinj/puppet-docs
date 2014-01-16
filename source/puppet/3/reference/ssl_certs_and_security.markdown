---
layout: default
title: "SSL: Certificates and Security"
---

[cert_sign]: TODO
[ssl_basics]: TODO
[autosigning]: TODO
[csr_attributes]: TODO
[external_ca]: TODO
[agent_web_server]: todo
[replace_expired_certificate]: todo
[attributes_and_extensions]: todo
[ssldir]: todo
[https_wiki]: todo
[masterport]: todo
[ssl_client_header]: todo
[ssl_client_verify_header]: todo
[http_endpoints]: /references/3.stable/developer/file.http_api_index.html
[certname]: todo
[dns_alt_names]: todo
[replace_mangled_certificate]: todo
[sign_alt_names]: todo
[autosign]: todo
[cadir]: todo
[cacrl]: todo
[cacert]: todo
[cakey]: todo
[capub]: todo
[cert_inventory]: todo
[caprivatedir]: todo
[capass]: todo
[csrdir]: todo
[serial]: todo
[signeddir]: todo
[requestdir]: todo
[hostcsr]: todo
[certdir]: todo
[hostcert]: todo
[localcacert]: todo
[hostcrl]: todo
[privatedir]: todo
[passfile]: todo
[privatekeydir]: todo
[hostprivkey]: todo
[publickeydir]: todo
[hostpubkey]: todo
[authorization]: todo
[auth_conf]: todo
[rest_authconfig]: todo

<!-- The following references are not used in the text:
[http_endpoints]:
-->

Puppet uses TLS/SSL (often referred to as simply "SSL;" in the Puppet Labs docs, we use the terms interchangeably) to secure its HTTPS communications. It includes a built-in certificate authority and several systems that use the certificates once they have been issued. This page describes the latter.

> Related Pages
> -----
>
> This page is background information about Puppet's SSL infrastructure. It does not cover _how_ to manage certificates and identity.
>
> Depending on your needs, you may want one of these other pages:
>
> ### Practical Information
>
> * [Signing and Managing Certificates with Puppet's CA][cert_sign] --- day-to-day instructions for managing certificates with Puppet's internal CA.
>
> ### Introductory Background
>
> * [SSL Basics][ssl_basics] --- a brief description of public key crypto and X.509 certificates.
>
> ### Advanced Practical Information
>
> * [Configuring Autosigning][autosigning] --- how to configure Puppet's CA to pre-approve new nodes.
> * [CSR Attributes and Certificate Extensions][csr_attributes] --- how to embed arbitrary information in CSRs, usually to enable more secure autosigning.
> * [Using an External CA][external_ca] --- the requirements for completely replacing Puppet's CA with an existing certificate infrastructure.




Certificates
-----

Puppet uses X.509 SSL certificates for encrypting communications and for authenticating nodes and services.

In this version of Puppet, all certificate and encryption infrastructure is based on OpenSSL.

### Names and Other Certificate Attributes

X.509 certificates can have many kinds of data embedded, but Puppet only uses a subset of this data.

* **Certname:** Puppet uses the CN ("common name") portion of the Subject field as the unique identifier for each certificate. Within Puppet, this is often referred to as the "certname" to distinguish it from other forms of identity.
    * When a puppet agent node or puppet master is requesting a certificate, it uses its [`certname` setting][certname] (which defaults to the node's fully qualified domain name) as the requested Subject CN. If a node's `certname` setting is changed after it already has a certificate, it assumes that certificate belongs to someone else and will request a new certificate with the new name.
    * Puppet does not use other portions of the Subject field (C, ST, O, OU, etc.) to distinguish nodes from each other. In certificates issued by Puppet's built-in CA, those fields are left blank and only the CN is specified.
* **Alternate DNS names:** In the "X509v3 extensions" section of the certificate, the "X509v3 Subject Alternative Name" subsection may include any number of "DNS:" entries, each of which should be a hostname. These entries allow the bearer of the certificate to present itself under any of these host names when acting as a server, which enables multiple puppet masters to have distinctive certnames but provide services at a common generic hostname (like puppet.example.com) behind a load balancer or proxy.
    * Alternate DNS names must be included in the original CSR, before the certificate is signed. When constructing a CSR, a Puppet node will use its [`dns_alt_names` setting][dns_alt_names] to decide which alternate names to request (if any). If a certificate is signed without the alternate names it needs, you must [replace it][replace_mangled_certificate].
    * Since alternate names can allow a node to impersonate another node when acting as a server, they are treated specially by Puppet's CA tools. In the Signing Certificates reference, see the section on [signing certificates with DNS alt names][sign_alt_names] for more detail.
    * In general, acting as a server means being a puppet master, but see also the section on [puppet agent's web server][agent_web_server] below.
* **Validity:** Each certificate has a period for which it is valid, with a start date and an end date. Outside that period, any agent or master presented with that certificate will consider it invalid and reject the connection. Expired certificates will have to be [replaced][replace_expired_certificate].
    * The CA sets the validity period when it signs a new certificate, using the value of its `ca_ttl` setting (defaults to five years).
* **Public key:** The public key embedded in the certificate is used for encrypting communications and verifying that the bearer of the certificate possesses the corresponding private key.
* **Signature:** The CA's signature proves that the bearer of this certificate is authorized to use Puppet services and go by the certname or any alternate DNS names in that certificate.
* **Constraints and Key Usage:** In the "X509v3 extensions" section of the certificate, there are several subsections that determine how the certificate can be used:
    * In the "X509v3 Basic Constraints" subsection, the "CA" entry determines whether the certificate can sign other certificates. Every Puppet certificate except the CA certificate should have `CA:FALSE` set. The CA certificate should have `CA:TRUE`.
    * In the "X509v3 Key Usage" subsection, the CA certificate should have the "Certificate Sign" and "CRL Sign" abilities, and no others. All other certificates should have the "Digital Signature" and "Key Encipherment" abilities, and no others.
    * The "X509v3 Extended Key Usage" subsection should be absent from the CA certificate. In all other certificates, it should include "TLS Web Server Authentication" and "TLS Web Client Authentication," and no other abilities.
* **Arbitrary extensions:** These are only used in a limited fashion today. See the page on [CSR attributes and cert extensions][attributes_and_extensions] for details.


### Default PKI Requirements

By default, Puppet is configured to require the following infrastructure:

* All certificates in use across the Puppet deployment **must** be signed by the same certificate authority (CA). (However, if you are using an [external CA][external_ca], it is possible to use two CAs instead of one.)
* All agent nodes **must** have a signed certificate. If they do not, they cannot request configuration data, although they can download the CA's credentials and request a certificate. It isn't strictly necessary for each node certificate to be unique, but it is highly recommended.
* Any puppet master server must have a signed certificate. Additionally, the hostname at which agent nodes contact it **must** be present in the certificate, either as the Subject CN value or as one of the Subject Alternative Name (DNS) values.

Puppet has built-in CA tools and certificate request tools to fulfill these requirements; alternately, an external CA can fulfill them. For details on how to issue certificates, see [Signing and Managing Certificates with Puppet's CA][cert_sign].

### Certificate Roles: Agent/Master and CA

There is essentially no difference between an agent certificate and a puppet master certificate. They both must have CA:FALSE in their "X509v3 Basic Constraints" subsection, and they both may contain one or more alternate DNS names.

This means that a puppet master certificate may also be used as a puppet agent certificate. A puppet master server may use puppet agent to fetch a catalog and configure itself; this entails contacting itself over HTTPS, presenting its certificate to itself to verify that it can provide services, presenting its certificate to itself to verify that it can access services, accepting the certificate both times, and carrying on as normal. By default, the puppet master would use the same copy of the certificate both times; however, it's also possible to configure the puppet master and puppet agent processes to use different `ssldir`s, by specifying different values for the setting in the `[agent]` and `[master]` config blocks. In this case, you would also need to specify distinct `certname` values in each block, since the CA will only permit one certificate to use a given certname.

By contrast, the CA certificate can only be used to sign certificates; it cannot be used to request a catalog or to provide services as a puppet master.

### The CA Puppet Master Server

Since the CA certificate cannot be used to provide services, agents never communicate directly with the CA; CA-related traffic passes through a puppet master, which may invoke CA functionality at certain times.

A master that accepts traffic on behalf of the Puppet CA is referred to as a "CA puppet master." A CA puppet master can:

* Accept CSRs from not-yet-authorized clients and store them for review
* Trigger autosigning on received CSRs, if configured (see [the Configuring Autosigning page][autosign])
* Serve existing signed certificates (including the CA certificate) to clients
* Serve a copy of the CRL to clients
* Serve information about certificate status to specifically authorized clients
* Allow specifically authorized clients to sign or revoke certificates

This refers only to the services the puppet master process provides over the network. In addition, a user with shell access and superuser privileges on the puppet master server can use the `puppet cert` command line tool to view certificate information and sign/revoke certificates. For details, see [Signing and Managing Certificates][cert_sign].


### The `ssldir` and Certificate Locations

All certificates, private keys, CSRs, and other crypto documents are stored on disk in PEM format in Puppet's "ssldir," whose location can be configured with the [`ssldir` setting][ssldir].  The permissions mode of the ssldir should be 0771, and it and every file it contains should be owned by the user Puppet runs as (i.e., root or Administrator on puppet agent nodes and defaulting to `puppet` on a puppet master server).

The layout of the ssldir is as follows:

* `ca` _(directory)_ --- Contains certificate authority (CA) infrastructure. This directory must only exist on the CA puppet master server, and only if you are using Puppet's built-in CA. Mode: 0770. Setting: [`cadir`][cadir].
    * `ca_crl.pem` --- The master copy of the certificate revocation list (CRL) managed by the CA. Mode: 0664. Setting: [`cacrl`][cacrl].
    * `ca_crt.pem` --- The CA's self-signed certificate. Mode: 0660. Setting: [`cacert`][cacert].
    * `ca_key.pem` --- The CA's private key. Tied for most security-critical file in the entire Puppet certificate infrastructure. Mode: 0660. Setting: [`cakey`][cakey].
    * `ca_pub.pem` --- The CA's public key. Mode: Not specified. Setting: [`capub`][capub].
    * `inventory.txt` --- A list of all certificates the CA has signed, along with their serial numbers and validity periods. Mode: 0644. Setting: [`cert_inventory`][cert_inventory].
    * `private` _(directory)_ --- Contains only one file. Mode: 0770. Setting: [`caprivatedir`][caprivatedir].
        * `ca.pass` --- The password to the CA's private key. Tied for most security-critical file in the entire Puppet certificate infrastructure. Mode: 0660. Setting: [`capass`][capass].
    * `requests` _(directory)_ --- Contains CSRs that were received but have not yet been signed. The CA deletes CSRs from this directory after signing them. Mode: Not specified. Setting: [`csrdir`][csrdir].
    * `serial` --- A file containing the serial number for the next certificate the CA will sign. Mode: 0644. Setting: [`serial`][serial].
    * `signed` _(directory)_ --- Contains certificates the CA has signed. Mode: 0770. Setting: [`signeddir`][signeddir].
* `certificate_requests` _(directory)_ --- Contains any CSRs generated by this node in preparation for submission to the CA. CSRs persist in this directory even after they have been submitted and signed. Mode: Not specified. Setting: [`requestdir`][requestdir].
    * `<certname>.pem` --- This node's CSR. Mode: 0644. Setting: [`hostcsr`][hostcsr].
* `certs` _(directory)_ --- Contains any signed certificates present on this node. This includes the node's own certificate, as well as a copy of the CA certificate (for use when validating certificates presented by other nodes). Mode: Not specified. Setting: [`certdir`][certdir].
    * `<certname>.pem` --- This node's certificate. Mode: 0644. Setting: [`hostcert`][hostcert].
    * `ca.pem` --- A local copy of the CA certificate. Mode: 0644. Setting: [`localcacert`][localcacert].
* `crl.pem` --- A copy of the certificate revocation list (CRL) retrieved from the CA, for use by puppet agent or puppet master. Mode: 0644. Setting: [`hostcrl`][hostcrl].
* `private` _(directory)_ --- Usually does not contain any files. Mode: 0750. Setting: [`privatedir`][privatedir].
    * `password` --- The password to a node's private key. Usually not present. The conditions in which this file would exist are not defined. Mode: 0640. Setting: [`passfile`][passfile].
* `private_keys` _(directory)_ --- Contains any private keys present on this node. This should generally only include the node's own private key, although on the CA it may also contain any private keys created by the `puppet cert generate` command. It will never contain the private key for the CA certificate. Mode: 0750. Setting: [`privatekeydir`][privatekeydir].
    * `<certname>.pem` --- This node's private key. Mode: 0600. Setting: [`hostprivkey`][hostprivkey].
* `public_keys` _(directory)_ --- Contains any public keys generated by this node in preparation for generating a CSR. Mode: Not specified. Setting: [`publickeydir`][publickeydir].
    * `<certname>.pem` --- This node's public key. Mode: 0644. Setting: [`hostpubkey`][hostpubkey].


HTTPS
-----

Network communication between agent nodes and puppet masters happens over industry-standard [HTTPS][https_wiki], which wraps the HTTP protocol with TLS/SSL.

* Most of Puppet's traffic also requires client authentication, so it behaves somewhat differently from most HTTPS on the public internet.
* Puppet's traffic is usually on port 8140 (configurable with the [`masterport` setting][masterport]) instead of the default HTTPS port of 443.

### Encryption

In HTTPS, all traffic is encrypted by SSL. This includes header information and the requested URL path --- there is no way to tell what the client requested until the request is decrypted. This provides in-transit protection for all of Puppet's traffic, so that eavesdroppers on the network cannot decrypt requests or replies.

Technically, the keys embedded in certificates are not used for traffic encryption; they are used to negotiate the secure exchange of a temporary key, which is then used for traffic encryption.

### Server Authentication

> **Note:** In general, "server" means either the puppet master server or whatever proxy is terminating SSL for it (see the section on SSL termination below). However, this can be reversed when using [puppet agent's web server][agent_web_server].

In SSL, a server must present a valid certificate (for which it possesses the corresponding private key) when clients connect to it. The client will use their copy of the CA certificate to validate the signature on the server's certificate. This allows clients to verify that the server is who it claims to be.

In human-centered over-the-internet HTTPS, the user of a client is presented with a verified organization name, and must use social knowledge about that organization to decide whether to trust the connection.

In Puppet, clients are configured ahead of time to connect to the server at a particular hostname. When presented with the certificate, they will check both the certname (Subject CN) and any alternate DNS names (X509v3 Subject Alternative Name), all of which have presumably been verified by the CA before signing the certificate. If the hostname the client reached the server at is included in that list of verified names, the client will treat the server as a trustworthy puppet master. If not, the client will reject the connection.

This means that a man-in-the-middle attacker cannot simply intercept an agent request and impersonate a puppet master; they would need the private key for a puppet master certificate that includes the hostname they are impersonating.

### Client Authentication

> **Note:** In general, "client" means the puppet agent application when contacting a puppet master server. However, this can be reversed when using [puppet agent's web server][agent_web_server].

Client authentication is an additional security measure available in TLS/SSL. It is not used by most HTTPS traffic on the public internet.

In client-authenticated SSL, the client must also present a valid certificate when connecting to a server. The client's certificate will be validated by the server to verify the client's identity. If the server disbelieves the client's identity, or if the identity is valid but not authorized to access a given resource, the server can reject the connection.

In Puppet's case, this means an agent node must have a signed certificate in order to access most of the services provided by the puppet master server. The list of service endpoints requiring client authentication can be configured in auth.conf; see below. By default, services involving configuration data (catalogs, facts, file content, etc.) require client auth, but unauthenticated clients can submit CSRs.

Once the client is authenticated, the server will also check to make sure the client is _authorized_ to access any given service. See ["Authorization"][authorization] below.

### Revoked Certificates

The Puppet CA maintains a certificate revocation list (CRL). This is a document that identifies certificates that are no longer trusted.

Clients regularly retrieve a copy of the CRL from the CA puppet master. (TODO: find out when.) A CA puppet master should already have access to the CRL; non-CA puppet masters must either regularly run puppet agent targeting a CA puppet master, or must have the CRL regularly deployed by some out-of-band process. (If you are using an external CA, you must distribute this file manually to all interested nodes.) Any SSL-terminating front-end web server for a puppet master must be configured to use the puppet master's CRL, and most web servers must be restarted in order to reload a CRL that has been changed.

If any certificate presented to a client or server is included in the CRL, that client or server will reject the connection, regardless of any other bona-fides in that certificate.

### Puppet Master Web Servers and SSL Termination

Since a puppet master provides services over HTTPS, it must run a web server, accept inbound connections, and terminate SSL.

* When bootstrapping a puppet master or testing that it is properly configured, Puppet can run a built-in web server based on Ruby's WEBrick library.
    * In this case, the puppet master runs as a single Ruby process and terminates SSL itself, using the configured CA and puppet master certificates. (Note that the WEBrick server cannot be used in a production deployment, as it is unable to handle simultaneous connections.)
* When running normally, the puppet master should be managed by a web server capable of running Rack applications. (For example: Apache using the Passenger module, or Unicorn with Nginx proxying requests to it.)
    * In this case, a front-end web server terminates SSL and passes some information to the puppet master process. There may be multiple layers of proxying involved, and the verification information must persist through all of them.
    * The front-end server must be configured to use the Puppet CA certificate to validate client identities, and to identify itself using the puppet master's certificate.
    * After validating a request, the front-end will insert validation information into the HTTP request headers. (These modified headers should persist through any additional proxies being used.) Then, whatever Rack server is managing the puppet master will set special environment variables based on the request headers, following the common gateway interface (CGI) standard. The puppet master process will then read the environment variables to check whether the request was validated and to find the certname of the client.
    * The default headers / variable names are `X-Client-DN` / `HTTP_X_CLIENT_DN` and `X-Client-Verify` / `HTTP_X_CLIENT_VERIFY`; these can be changed by configuring the front-end web server to insert information into different headers, translating those headers to CGI-style environment variable names, then using those variable names as the new values for the [`ssl_client_header`][ssl_client_header] and [`ssl_client_verify_header`][ssl_client_verify_header] settings in the puppet master's puppet.conf.

### Differences Between Agent/Master and Standalone Puppet Apply

In an agent/master deployment, a node being managed by Puppet will use HTTPS to do most or all of the following:

* Download a node object (containing information like its environment) from a puppet master
* Download plugins (like custom facts, types, and providers) from a puppet master
* Upload its facts to a puppet master
* Download a catalog from a puppet master
* Upload its report to a puppet master

By default, nodes running puppet apply to locally compile and apply their catalogs won't contact a puppet master for any of these things. However, a puppet apply node can be configured to:

* Download plugins from a puppet master
* Upload its facts to a PuppetDB server
* Download exported resources from a PuppetDB server
* Upload its catalog to a PuppetDB server

All of these tasks would still use client-authenticated HTTPS, and the node would still require a signed certificate for them.



Authorization
-----

The agent's identity determines which services it is authorized to access on the master. These permissions are controlled by the master's HTTP authorization config file, `auth.conf`.

### Puppet Master's HTTP Endpoints

The puppet master provides several services over HTTPS. These network services make up the complete interface between the puppet master and any puppet agent nodes.

Each service is presented as an HTTP "endpoint." This is a fuzzy term


### auth.conf


> For practical information on auth.conf's syntax and capabilities, [see the auth.conf documentation][auth_conf].

The auth.conf file is an ordered list of access rules. Each request that comes in

The location of auth.conf defaults to `/etc/puppetlabs/puppet/auth.conf` for Puppet Enterprise and `/etc/puppet/auth.conf` for open source Puppet. It can be configured with the [`rest_authconfig` setting][rest_authconfig].


#### Authenticated and Unauthenticated Services

### Certname vs. Node Name

#### Referencing the Certname in Puppet Manifests

#### Referencing the Node Name in Puppet Manifests

### Secondary Validation Systems (fileserver.conf)


Authorizing Non-Puppet-Agent Clients
-----

### Issuing Certificates

### Using Client Certificates with Curl


Puppet Agent's Web Server (Puppet Kick)
-----

> **Deprecation note:** The agent web server is deprecated, mostly because opening a port on every agent node turned out to not be the best idea. It will be removed in a future version of Puppet. You can use MCollective with the Puppet plugin to trigger runs today, and we're investigating lighter weight orchestration solutions for triggering Puppet runs.

### Enabling the Agent Server

### Authorizing Access for the Run Service
