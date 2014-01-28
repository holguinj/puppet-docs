---
layout: default
title: "Background Reference: SSL-Related Topics"
---


Puppet's network communications and security are all based on HTTPS, which secures traffic using X.509 certificates.

These tools and protocols can sometimes present a steep learning curve for new Puppet users. This page provides background knowledge about how SSL and certificates work, and is aimed at giving new Puppet users enough fluency with these concepts to read and understand the rest of the SSL documentation on this site. Once you are familiar with the basic concepts, other documentation on this site has practical instructions about how to manage certificates and security. See the [list of resources][ssl_links_inpage] at the bottom of this page for details.

Note that this background information is vastly simplified and glosses over any number of implementation complexities. If you're interested in learning more, it should provide enough context and vocabulary to research these topics in more depth. (The Wikipedia pages on [PKI][wiki_pki] and [TLS/SSL][wiki_tls] may be a good starting place; after that, we recommend hitting the library or your local technical book store.)


Public Key Cryptography
-----

The term **public key cryptography** generally means a family of algorithms and practices for encrypting and verifying information.

* In public key crypto, each participant possesses a _key pair,_ which consists of a _public key_ and a _private key._ These are both large, nearly-impossible-to-guess numbers, which are mathematically related to each other in a specific way. (The actual mathematics are far outside the scope of this guide.)
    * Any public key has one (and only one) corresponding private key, and vice-versa.
    * The public key can and should be shared freely.
    * The private key must stay private. If a copy of it is stolen, the thief can impersonate the rightful owner until all other participants have stopped using and trusting the corresponding public key.
    * A private key can't be reverse-engineered from its corresponding public key. (Or at least, doing so isn't practical with current or foreseeable-future technology.)
* If you have the _public_ part of a given key pair, you can _encrypt_ a message so that it can only be decrypted by whoever possesses the corresponding _private_ key.
* If you have the _private_ part of a given key pair, you can _digitally sign_ a message, which means anyone possessing the corresponding _public_ key can:
    * Prove that whoever signed the message is (or was) actually in possession of that private key.
    * Determine whether the message was altered after the signature was made.

To be useful for real-world purposes, a public key crypto scheme must be combined with some other system that links known keypairs to some form of _identity._ (Otherwise, they're just big annoying numbers.) This can be a local registry (think handwritten phone book, or SSH keys), a central registry (think DNS), a signature-based system (think driver's licence), or some combination of them.


Certificates and Public Key Infrastructure
-----

A public key infrastructure (PKI) is a way to associate public keys with trusted information about their owners. In other words, it serves the purpose described at the end of the previous section.

The PKI used in SSL/TLS is defined by [the X.509 standard][x509]. Puppet and Puppet Enterprise use OpenSSL's implementation of the X.509 PKI.

### What Certificates Are

A **certificate** is a cryptographic identification document that contains:

* A _public key_
* _Metadata_ about the certificate and its owner
* A _signature_ from the certificate authority (CA), which is a trusted third party

These parts work together to form a useful unit of trust:

* The public key lets you determine whether the entity you're talking to possesses the corresponding private key, and enables secure communication with them.
* The metadata tells you who that entity is, what they are allowed to do, and how long their certificate is valid.
* The signature proves that someone you trust has done a background check on the key pair's owner, and has gone on record stating that the metadata in the certificate is correct. It also prevents tampering with any of the information in the certificate: if any part is changed, the signature will fail to validate.

Certificates are usually stored in some encoded format. The most common format is PEM (privacy-enhanced mail), but certs may also be stored in archives such as Java keystores. These encoded formats are not human-readable, and need to be dumped into a different format to be inspected by users.

(Puppet stores certificates in PEM format, and the CA tools include a `puppet cert print` command for dumping certificates to the terminal.)

### Contents of a Certificate

For more details about the metadata available in a certificate, such as the difference between the CN and the DN, please see [the appendix on certificate anatomy][certificate_anatomy].

### Certificate Authorities

Participants in a PKI generally agree ahead of time to trust a limited number of certificate authorities (CAs). The CAs that are trusted before any other infrastructure is set up are called "root" CAs; later, some root CAs might issue "intermediate" or "chained" CA certificates, which are allowed to sign new certificates but can also be validated and revoked like normal certificates.

Fundamentally, a CA is just a trusted person or institution that controls a key pair. The following steps are what differentiate the CA from any other participant in the PKI:

* Other participants agree to trust that key pair's owner as a CA. For a root CA, this is usually a social/legal/contractual agreement that originates outside the PKI. For an intermediate CA, participants will trust it because they trust the root CA that endorses it.
* The CA either creates or obtains a special certificate, whose metadata states that the CA is allowed to sign new certificates.
    * For intermediate CAs, this certificate is issued by another (probably root) CA. Root CAs will use their own key pair to craft a _self-signed certificate._ (That is, the signature is provided by the same key pair that the certificate describes. This is why the decision to trust a root CA happens outside the PKI: their certificates amount to a tautological "trust me because you trust me.")
* The CA certificate is distributed to other participants in the PKI. This is often done out-of-band as part of some bootstrapping process. (For example, the root CA certificates used by web browsers can be bundled with the executable and installed alongside it. Most modern operating systems also ship with root CA certs included.)

At this point, other participants can use the CA's certificate to verify signatures on any certificates that claim to be vetted by that CA. If the signature fails to validate, they will consider that certificate forged and decline to trust it.

### Certificate Signing Requests

Once the foundation of CA trust is established, participants can send certificate signing requests (CSRs) to the CA. The process depends on the CA; it might involve a ream of paperwork, or an email and a phone call, or an HTTP request to some automated system.

A CSR is a specially formatted cryptographic document that contains the applicant's public key and any metadata (name, etc.) that the applicant wants to have in their certificate. (In terms of content, it's just a certificate minus the CA signature.)

The CA can double-check this metadata, verify that the key pair belongs to the applicant, and perform any background checks it considers necessary. It will then choose whether or not to sign the request with its private key.

Signing the request will create a new certificate for the participant that requested it. That participant will then have to retrieve the certificate from the CA. (The process for doing so will vary depending on the CA's preferences.) Once the participant has it, they can present the certificate to other participants and use their private key to prove themselves as the certificate's rightful owner. Other participants can use the CA's signature to prove that the metadata in the certificate was vetted by that CA.

### Certificate Revocation Lists

Trusted certificates sometimes need to become untrusted, often as a result of a security breach. To handle this, a CA will maintain a certificate revocation list (CRL), which contains the serial numbers of any certificates that should no longer be trusted.

Participants in the PKI should regularly retrieve a copy of each CA's CRL, and should double-check certificates against it when checking their validity.

### Certificate Lifespans

Each certificate has a period of time for which it is valid; before or after this timespan, the certificate should not be trusted. The validity period is embedded in the certificate's metadata, and is assigned by the CA when signing the certificate.

When checking a certificate's validity, participants in a PKI should check also ensure that the certificate has not expired.

### Attacks on PKI Trust

The central idea of a PKI is that you can vet and then trust a small number of entities, and they will subsequently tell you whether to trust any number of other entities. Small initial decision, large ongoing utility.

Due to the shape of this trust arrangement, most attacks on a PKI will tend to fit a certain number of fundamental patterns:

* **Subvert the CA's owner.** If you can coerce or manipulate the person or organization behind the CA, you can easily obtain fraudulent certificates that are indistinguishable from legitimate ones. These can be used to impersonate other participants in a man-in-the-middle attack, or to provide legitimacy for some other shenanigans. The only way for other participants to recover is to burn that CA permanently, which will have hugely disruptive effects; any participants with certificates from that CA will need to become re-certified under a new CA.
* **Subvert the CA's credentials.** If you can steal the CA's private key or get temporary access to it, you can issue your own forged certificates and do basically the same thing as above. Since the CA won't know about these certificates, you may end up with duplicated serial numbers, but these are only a problem if someone who has seen your forged certs in the wild can correlate them with the set of all legit certificates. (Basically: if the CA gets wind of it, the gig is up.) Duped serial numbers can also make it difficult for the CA to effectively revoke your forged certs. The only way for other participants to recover is to stop trusting that CA's certificate permanently and either replace it or stop trusting the entity behind the CA. All existing participants will need to be re-certified with the new CA credentials.
* **Trick the CA.** If the CA is lax in its background checks, a rogue participant may submit fraudulent metadata (for example, using the name of an organization they don't actually represent) and have it signed into a legit certificate. This may allow them to impersonate other actors. To recover, the CA must revoke that certificate and all participants must be using good CRL hygiene when validating certificates.
    * (A fun example was Puppet's [CVE-2011-3872](http://puppetlabs.com/security/cve/cve-2011-3872), where the CA could be configured to trick _itself_ into silently adding forged metadata to agent certs.)
* **Subvert participants' credentials.** If you can get access to a participant's private key, you can impersonate them at will. To recover, the CA will need to revoke their certificate and they will need to get re-certified.
* **Subvert a participant's list of trusted CAs.** If you can insert an evil CA certificate into a user's collection of CA certs, they will often trust certificates issued by that rogue CA. (This could be done by, e.g., redirecting a user to a doctored browser executable with bogus root CAs inserted. It could also be done with a trojan or other means of partial control over the user's computer.) To recover, the user would need to be keeping track of their trusted CAs, and would need to remove the evil one and patch whatever vulnerability allowed it to be placed there.
* **Attack the implementation.** If you can find a vulnerability in the protocol that is using the PKI --- for example, a cipher crack or the BEAST and CRIME attacks on SSL/TLS --- you may be able to steal information from or insert information into the secure channel without actually needing to attack the PKI itself. To recover or defend, the participants must make sure they're using a version of their protocol that isn't vulnerable to that attack.
* **Attack outside the protocol.** If the target terminates SSL and sends unencrypted traffic over leased fiber, attack the leased fiber. Or get a keylogger onto the target's machine, or something; the point is, cheating is easier and more effective than fussing with a PKI or a secure protocol.

In short: protect your private keys, make sure you actually trust the CA (in intentions _and_ competence), stay up to date on protocol exploits, and above all keep an eye on the unsecured portions of your system.

TLS/SSL
-----

TLS is a protocol that uses an X.509 PKI to create secure channels of network communication. SSL is an older version of that same protocol, which is still in widespread use.

> ### Notes on Those Names
>
> They both refer to essentially the same thing. Informally, many people (including us at Puppet Labs) often just say "SSL" to refer to any combination of TLS and SSL, mostly because old habits die hard.
>
> Most tools can use multiple versions of the protocol, and the combination of versions they support will often cross the arbitrary TLS/SSL boundary. (Usually something like SSL 3.0, TLS 1.0, and TLS 1.1.) Since clients and servers can negotiate versions on the fly, the exact protocol you'll be using at any given moment depends on the configuration of every tool that might interact with the system.

### Starting an SSL Connection

SSL always has two participants: a client, which initiates the connection, and a server, which accepts incoming connections. (These are flexible identities: Depending on how a system works, the same entity may act as a client sometimes and a server at other times.)

After a client starts the process, an SSL connection involves the following procedures:

* The client and server negotiate to figure out which cipher and protocol version to use.
* The server presents its certificate.
    * The client software validates that certificate, based on its list of trustworthy CAs, the CRLs it has available, and the validity period of the certificate. If it won't validate, the client bails.
* **Optionally,** the client can present a certificate of its own to the server, along with proof that it possesses the corresponding private key. The server will validate that certificate before continuing.
    * This only happens if the server explicitly requests "client authentication." Most HTTPS sites on the web don't require client authentication. Puppet, however, does (for certain services).
* The client sends a temporary "session" key to the server, encrypted so that only the owner of the server certificate can read it.
* Both client and server use that session key to encrypt all subsequent traffic in the connection.

### Specific Advantages of an SSL Connection

After the connection starts, the two parties have the following tools and extra information:

#### Both Parties

Both parties have access to an encrypted communication channel, which can't be eavesdropped on.

#### The Client

Since the client has seen the server's certificate, it has a bunch of extra information about the server:

* It knows it is talking to the rightful owner of the server certificate (since only the rightful owner could have decrypted that session key).
* It knows the CA verified any metadata in the certificate.
* It can use any metadata in the server certificate to **authenticate** and **authorize** the server. Some of this authorization may be simple and automatic, and some may require more consideration. As an example, consider what a web browser and its user do in a standard web HTTPS connection:
    * Web SSL certificates contain a list of domain names that are allowed to present that certificate. The web browser automatically checks for the domain name it contacted in that list. If it isn't included, the browser can refuse to let the user continue.
    * Certificates also list the name of the organization that was issued the certificate, and web browsers present that name to the user. (Usually behind a little padlock icon.) If the user checks that organization name and doesn't believe that it matches the rightful operator of the website they think they're visiting, they may choose to distrust and bail.
    * A website may ask for sensitive information that the user is only willing to share with certain trusted parties. If the user checks the organization name in the certificate and doesn't wish to share that information with that organization, they may decide not to provide it.

#### The Server

If client authentication wasn't requested, the server doesn't know anything in particular about the client --- any authentication of the client's identity or authorization of its permissions has to happen by some other means, like the login form on a web page.

If client authentication **was** requested (and accepted), the server has information comparable to what the client gets:

* It knows it is talking to the rightful owner of the client certificate, since the client proved itself when providing the certificate.
* It knows the CA verified any metadata in the certificate.
* It can use any metadata in the client certificate to **authenticate** and **authorize** the client.
    * For example, the server may protect certain resources by only allowing certain clients to access them. This could be done by maintaining a list of allowed client names, or by looking for some token that was embedded in the client's certificate when it was signed.


HTTPS
-----

Since SSL is a relatively generic protocol, it is usually used to wrap a more specific protocol, like HTTP or SMTP.

HTTPS is the standard HTTP protocol wrapped with SSL --- an SSL connection is established as described above, then the client sends normal HTTP requests to the server over the secure channel. When the server answers, it also uses the secure channel.

The entire protocol is wrapped, including headers; this means that even URLs, parameters, and POST data will be encrypted.

Puppet uses HTTPS for all of its traffic. Most of its HTTP endpoints require client authentication, to ensure nodes cannot request configurations that should only be served to some other node. However, certain endpoints can be used without client authentication, mostly so that new nodes can retrieve a copy of the CA certificate and submit CSRs.

### Ports

Technically, any port can be used to serve HTTPS. On the web, the usual convention is port 443.

Puppet usually uses port 8140 instead, since its traffic doesn't really resemble web traffic.

### Persistence of SSL/Certificate Data in HTTPS Applications

Since the entire HTTP protocol passes through the secure channel established by the SSL connection, the HTTP server and client don't have any direct involvement with the connection or the certificates. Likewise, any application logic will be several levels removed from the SSL details.

In practice, though, other levels of an application will usually want access to some SSL-related information:

* The client application usually wants to examine the certificate metadata after the connection is established, since the server's identity and permissions are relevant to application-level authorization decisions. (For example, a user could check the identity of a server before deciding whether to enter sensitive information into a web form.)
* If client authentication is enabled, the server application will want to know whether the authentication succeeded, and will want to examine the results.

Thus, most SSL implementations have some means to publish connection and certificate data, so it can be used by higher layers of the protocol stack.

An example of this is Apache's `mod_ssl` module. If it's [configured with the `StdEnvVars` option](http://httpd.apache.org/docs/2.2/mod/mod_ssl.html#envvars), it will publish extensive SSL and certificate information as environment variables with predictable names. These variables can then be used by Apache itself, or by any application being spawned and managed by another Apache module (e.g. `mod_passenger` or `mod_php`). This is how the puppet master accesses

### SSL Termination and Proxying

Large server-side HTTPS applications often need to be split into multiple semi-independent components or services, in order to accommodate better resiliency or performance. SSL is often the first component to go; even in cases where most of the application runs as a single process, SSL is computationally expensive enough to be worth splitting out.

A single component that handles SSL in a service-oriented-architecture is called an _SSL terminating proxy._ SSL proxies work under basically the same requirements as the SSL component of a purely local application stack --- they must validate certificates and provide a secure channel, and they may need to publish connection and certificate information for use by other components of the stack. They also introduce one additional requirement: the network between the proxy and the application server must be very secure, as sensitive information will be passing along it in cleartext.

[ssl_terminating_proxy]: ./ssl_terminating_proxy.jpg

![A drawing of an SSL terminating proxy removing SSL and sending a second unencrypted HTTP request with certificate data embedded in the headers.][ssl_terminating_proxy]

SSL terminating proxies do this by handling the incoming connection, then sending a second unencrypted HTTP request to the real application server. When they receive a reply, they will forward it to the client along the original secure connection.

If the application needs any SSL or certificate data, the proxy can be configured to publish it by inserting the data into the HTTP headers of the second request.

An example of this is a puppet master running with the Nginx + Unicorn stack:

* Nginx terminates SSL, and inserts the SSL client authentication status and client certificate DN into the HTTP headers of a new request. It sends this request to the Unicorn workers.
* A Unicorn worker receives the unencrypted request, and, according to the common gateway interface (CGI) standard, publishes all HTTP header information as CGI variables, including the SSL information inserted by Nginx. It uses the Rack interface to translate the HTTP request into a request to the puppet master application.
* The puppet master application reads SSL information from pre-arranged environment variables, and uses its auth.conf configuration to decide whether to serve the request. If yes, it uses its own application logic to decide what the request should be. Any response passes back through the Unicorn worker and Nginx to make its way to the puppet agent client.



