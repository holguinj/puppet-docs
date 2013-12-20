---
layout: default
title: "SSL: Certificates and Security"
---

[cert_sign]: TODO
[ssl_basics]: TODO
[autosigning]: TODO
[csr_attributes]: TODO
[external_ca]: TODO

Puppet uses TLS/SSL (usually referred to as simply "SSL" on this site) to secure its HTTPS communications. It includes a built-in certificate authority and several systems that use the certificates once they have been issued. This page describes the latter.

> Related Pages
> -----
>
> This page focuses on background information about how Puppet's HTTPS and authentication/authorization systems work. If you are looking for information about _how_ to manage certificates and identity, you may need a different page.
>
> ### Basic Information
>
> * [Signing and Managing Certificates with Puppet's CA][cert_sign] --- practical day-to-day instructions for managing certificates with Puppet's internal CA.
> * [SSL Basics][ssl_basics] --- a brief description of public key crypto and X.509 certificates.
>
> ### Advanced Information
>
> * [Configuring Autosigning][autosigning] --- how to configure Puppet's CA to pre-approve new nodes.
> * [CSR Attributes and Certificate Extensions][csr_attributes] --- how to embed arbitrary information in CSRs, usually to enable more secure autosigning.
> * [Using an External CA][external_ca] --- the requirements for completely replacing Puppet's CA with an existing certificate infrastructure.




Certificates
-----

Puppet uses X.509 certificates for encrypting communications and for authenticating nodes and services.

In this version of Puppet, all certificate and encryption infrastructure is based on OpenSSL.

### Names and Other Certificate Attributes

X.509 certificates can have many kinds of data embedded, but Puppet only uses a subset of this data.

* **Certname:** Puppet uses the CN ("common name") portion of the Subject field as the unique identifier for each certificate.
    * When a puppet agent node or puppet master is requesting a certificate, it uses its `certname` setting (which defaults to the node's fully qualified domain name) as the requested Subject CN.
    * If a node's `certname` setting is changed after it has a certificate, it will assume that certificate belongs to someone else and request a new certificate with the new name.
* **Alternate DNS names:** In the "X509v3 extensions" section of the certificate, the "X509v3 Subject Alternative Name" subsection may include any number of "DNS:" entries, each of which should be a hostname. These entries allow the bearer of the certificate to present itself under any of these host names when acting as a server, which allows multiple puppet masters to have distinctive certnames but provide services at a common generic hostname (like puppet.example.com).
    * In general, acting as a server means being a puppet master, but see also the section on [puppet agent's web server][agent_web_server] below.
* **Validity:** Each certificate has a period for which it is valid, with a start date and an end date. Outside that period, any agent or master presented with that certificate will consider it invalid and reject the connection. Expired certificates will have to be [replaced][replace_expired_certificate].
    * The CA sets the validity period when it signs a new certificate, using the value of its `ca_ttl` setting (defaults to five years).
* **Public key:** The public key embedded in the certificate is used for encrypting communications and verifying that the bearer of the certificate possesses the corresponding private key.
* **Signature:** The CA's signature proves that the bearer of this certificate is authorized to use Puppet services and go by the certname or any alternate DNS names in that certificate.
* **CA permissions:** In the "X509v3 extensions" section of the certificate ("X509v3 Basic Constraints" subsection), the "CA" entry determines whether the certificate can sign other certificates. Every Puppet certificate except the CA certificate should have `CA:FALSE` set.


### Certificate Storage / `ssldir`

All certificates, private keys, CSRs, and other crypto documents are stored on disk in PEM format in Puppet's "ssldir," whose location can be configured with the [`ssldir` setting][ssldir]. The permissions mode of the ssldir should be 0771, and it and every file it contains should be owned by the user Puppet runs as (i.e., root or Administrator on puppet agent nodes and defaulting to `puppet` on a puppet master server).

The layout of the ssldir is as follows:

* `ca` _(directory)_ --- Contains certificate authority (CA) infrastructure. Exists on: The CA puppet master server. Mode: 0770. Setting: `cadir`.
    * `ca_crl.pem` --- The master copy of the certificate revocation list (CRL) managed by the CA. Mode: 0664. Setting: `cacrl`.
    * `ca_crt.pem` --- The CA's self-signed certificate. Mode: 0660. Setting: `cacert`.
    * `ca_key.pem` --- The CA's private key. Tied for most security-critical file in the entire Puppet certificate infrastructure. Mode: 0660. Setting: `cakey`.
    * `ca_pub.pem` --- The CA's public key. Mode: Not specified. Setting: `capub`.
    * `inventory.txt` --- A list of all certificates the CA has signed, along with their serial numbers and validity periods. Mode: 0644. Setting: `cert_inventory`.
    * `private` _(directory)_ --- Contains only one file. Mode: 0770. Setting: `caprivatedir`.
        * `ca.pass` --- The password to the CA's private key. Tied for most security-critical file in the entire Puppet certificate infrastructure. Mode: 0660. Setting: `capass`.
    * `requests` _(directory)_ --- Contains CSRs that were received but have not yet been signed. The CA deletes CSRs from this directory after signing them. Mode: Not specified. Setting: `csrdir`.
    * `serial` --- A file containing the serial number for the next certificate the CA will sign. Mode: 0644. Setting: `serial`.
    * `signed` _(directory)_ --- Contains certificates the CA has signed. Mode: 0770. Setting: `signeddir`.
* `certificate_requests` _(directory)_ --- Contains any CSRs generated by this node in preparation for submission to the CA. CSRs persist in this directory even after they have been submitted and signed. Mode: Not specified. Setting: `requestdir`.
    * `<certname>.pem` --- This node's CSR. Mode: 0644. Setting: `hostcsr`.
* `certs` _(directory)_ --- Contains any signed certificates present on this node. This includes the node's own certificate, as well as a copy of the CA certificate (for use when validating certificates presented by other nodes). Mode: Not specified. Setting: `certdir`.
    * `<certname>.pem` --- This node's certificate. Mode: 0644. Setting: `hostcert`.
    * `ca.pem` --- A local copy of the CA certificate. Mode: 0644. Setting: `localcacert`.
* `crl.pem` --- A copy of the certificate revocation list (CRL) retrieved from the CA, for use by puppet agent or puppet master. Mode: 0644. Setting: `hostcrl`.
* `private` _(directory)_ --- Usually does not contain any files. Mode: 0750. Setting: `privatedir`.
    * `password` --- The password to a node's private key. Usually not present. The conditions in which this file would exist are not defined. Mode: 0640. Setting: `passfile`.
* `private_keys` _(directory)_ --- Contains any private keys present on this node. This should generally only include the node's own private key, although on the CA it may also contain any private keys created by the `puppet cert generate` command. It will never contain the private key for the CA certificate. Mode: 0750. Setting: `privatekeydir`.
    * `<certname>.pem` --- This node's private key. Mode: 0600. Setting: `hostprivkey`.
* `public_keys` _(directory)_ --- Contains any public keys generated by this node in preparation for generating a CSR. Mode: Not specified. Setting: `publickeydir`.
    * `<certname>.pem` --- This node's public key. Mode: 0644. Setting: `hostpubkey`.


### Default PKI Requirements

By default, Puppet is configured to require the following infrastructure:

* All certificates in use across the Puppet deployment **must** be signed by the same certificate authority (CA). (However, if you are using an [external CA][external_ca], it is possible to use two CAs instead of one.)
* All agent nodes **must** have a signed certificate. If they do not, they cannot request configuration data, although they can download the CA's credentials and request a certificate.
* Any puppet master server must have a signed certificate. Additionally, the hostname at which agent nodes contact it **must** be present in the certificate, either as the Subject CN value or as one of the Subject Alternative Name (DNS) values.

Puppet has built-in CA tools to fulfill these requirements; alternately, an external CA can fulfill them. For details on how to issue certificates, see [Signing and Managing Certificates with Puppet's CA][cert_sign].


HTTPS
-----

All of Puppet's network traffic is HTTPS --- that is, HTTP over TLS/SSL. Traffic is usually on port 8140 (configurable with the [`masterport` setting][masterport]).

A full explanation of HTTPS is beyond the scope of this page (start with [the Wikipedia page for HTTPS](http://en.wikipedia.org/wiki/HTTP_Secure) and continue from there), but in general,

### Client Authentication (Or Not)

### Terminating SSL with a Front-end Web Server

### Differences Between Agent/Master and Standalone Puppet


Authentication
-----

### Agents Validate the Master's Identity

#### DNS Alt Names


### Masters Validate Agent Identities

### Revoked Certificates



Authorization
-----

The agent's identity determines which services it can access on the master.

### auth.conf and the Puppet Master's Services

#### Authenticated and Unauthenticated Services

### Certname vs. Node Name

#### Referencing the Certname in Puppet Manifests

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
