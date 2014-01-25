---
layout: default
title: "Background Reference: SSL-Related Topics"
---


Puppet's network communications and security are all based on HTTPS, which secures traffic using X.509 certificates.

These tools and protocols can sometimes present a steep learning curve for new Puppet users. This page provides background knowledge about how SSL and certificates work, and is aimed at giving new Puppet users enough fluency with these concepts to read and understand the rest of the SSL documentation on this site. Once you are familiar with the basic concepts, other documentation on this site has practical instructions about how to manage certificates and security. See the [list of resources][ssl_links_inpage] at the bottom of this page for details.

Note that this background information is vastly simplified and glosses over any number of implementation complexities. If you're interested in learning more, it should provide enough context and vocabulary to research these topics in more depth. ([The Wikipedia page on PKI][wiki_pki] may be a good starting place; after that, we recommend hitting the library or your local technical book store.)


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

### Certificate Authorities

Participants in a PKI generally agree ahead of time to trust a limited number of certificate authorities (CAs). The CAs that are trusted before any other infrastructure is set up are called "root" CAs; later, some root CAs might issue subordinate or "chained" CA certificates.

Fundamentally, a CA is just a trusted person or institution that controls a key pair. The following steps are what differentiate the CA from any other participant in the PKI:

* Other participants agree to trust that key pair's owner as a CA. For root CAs, this is usually a social/legal/contractual agreement that originates outside the PKI.
* The CA either creates or obtains a special certificate, whose metadata states that the CA is allowed to sign new certificates.
    * For chained CAs, this certificate is issued by another (probably root) CA. Root CAs will use their own key pair to craft a _self-signed certificate._ (That is, the signature is provided by the same key pair that the certificate describes. This is why the decision to trust a root CA happens outside the PKI: their certificates amount to a tautological "trust me because you trust me.")
* The CA certificate is distributed to other participants in the PKI. This is often done out-of-band as part of some bootstrapping process. (For example, the root CA certificates used by web browsers can be bundled with the executable and installed alongside it. Most modern operating systems also ship with root CA certs included.)

At this point, other participants can use the CA's certificate to verify signatures on any certificates that claim to be vetted by that CA. If the signature fails to validate, they will consider that certificate forged and decline to trust it.

### Certificate Signing Requests

Once the foundation of CA trust is established, participants can send certificate signing requests (CSRs) to the CA. The process depends on the CA; it might involve a ream of paperwork, or an email and a phone call, or an HTTP request to some automated system.

A CSR is a specially formatted cryptographic document that contains the applicant's public key and any metadata that the applicant wants to have in their certificate. (In terms of content, it's just a certificate minus the CA signature.)

The CA can double-check this metadata, verify that the key pair belongs to the applicant, and perform any background checks it considers necessary. It will then choose whether or not to sign the request with its private key.

Signing the request will create a new certificate for the participant that requested it. That participant will then have to retrieve the certificate from the CA. (Again, the process may vary depending on the CA's preferences.) Once the participant has it, they can present the certificate to other participants and use their private key to prove themselves as the certificate's rightful owner. Other participants can use the CA's signature to prove that the metadata in the certificate was vetted by that CA.

### Certificate Revocation Lists

Trusted certificates sometimes need to become untrusted, often as a result of a security breach. To handle this, a CA will maintain a certificate revocation list (CRL), which contains the serial numbers of any certificates that should no longer be trusted.

Participants in the PKI should regularly retrieve a copy of each CA's CRL, and should double-check certificates against it when checking their validity.

### Certificate Lifespans

Each certificate has a period of time for which it is valid; before or after this timespan, the certificate should not be trusted. The validity period is assigned by the CA when signing the certificate.

When checking a certificate's validity, participants in a PKI should check also ensure that the certificate has not expired.

### Attacks on PKI Trust

The central idea of a PKI is that you can vet and then trust a small number of entities, and they will subsequently tell you whether to trust any number of other entities. Small initial decision, large ongoing utility.

Due to the shape of this trust arrangement, most attacks on a given PKI will tend to fit a certain number of fundamental patterns:

* **Subvert the CA's owner.** If you can coerce or manipulate the person or organization behind the CA, you can easily obtain fraudulent certificates that are indistinguishable from legitimate ones. These can be used to impersonate other participants in a man-in-the-middle attack, or to provide legitimacy for some other shenanigans. The only way for other participants to recover is to burn that CA permanently, which will have hugely disruptive effects; any participants with certificates from that CA will need to become re-certified under a new CA.
* **Subvert the CA's credentials.** If you can steal the CA's private key or get temporary access to it, you can issue your own forged certificates and do basically the same thing as above. Since the CA won't know about these certificates, you may end up with duplicated serial numbers, but these are only a problem if someone who has seen your forged certs in the wild can correlate them with the set of all legit certificates. (Basically: if the CA gets wind of it, the gig is up.) Duped serial numbers can also make it difficult for the CA to effectively revoke your forged certs. The only way for other participants to recover is to stop trusting that CA's certificate permanently and either replace it or stop trusting the entity behind the CA. (After all, they failed to protect their private key.) All existing participants will need to be re-certified with the new CA credentials.
* **Trick the CA.** If the CA is lax in its background checks, a rogue participant may submit fraudulent metadata (for example, using the name of an organization they don't actually represent) and have it signed into a legit certificate. This may allow them to impersonate other actors. To recover, the CA must revoke that certificate and all participants must be using good CRL hygiene when validating certificates.
* **Subvert participants' credentials.** If you can get access to a participant's private key, you can impersonate them at will. To recover, the CA will need to revoke their certificate and they will need to get re-certified.
* **Subvert a participant's list of trusted CAs.** If you can insert an evil CA certificate into a user's collection of CA certs, they will often trust certificates issued by that rogue CA. This generally requires you to gain at least partial control of the user's computer anyway, but it can enable new and hard-to-detect forms of subsequent attack. To recover, the user would need to be keeping track of their trusted CAs, and would need to remove the evil one and patch whatever vulnerability allowed it to be placed there.
* **Attack the implementation.** If you can find a vulnerability in the protocol that is using the PKI --- for example, a cipher crack or the BEAST and CRIME attacks on SSL/TLS --- you may be able to steal information from or insert information into the secure channel without actually needing to attack the PKI itself. To recover or defend, the participants must make sure they're using a version of their protocol that isn't vulnerable to that attack.
* **Attack outside the implementation.** If you have a keylogger installed on a participant's machine, you can get whatever you want without having to fuss with the PKI or the secure protocol at all. (Or if they terminate SSL and send unencrypted traffic over leased fiber, attack the leased fiber.)

In short: protect your private keys, make sure you actually trust the CA (in intentions _and_ competence), stay up to date on protocol exploits, and above all keep an eye on the unsecured portions of your system.

TLS/SSL
-----

TLS is a protocol that uses an X.509 PKI to create secure channels of communication. SSL is an older version of that same protocol, which is still in widespread use.

### Notes on Those Names

They both refer to essentially the same thing. Informally, many people (including us at Puppet Labs) often just say "SSL" to refer to any combination of TLS and SSL, mostly because old habits die hard.

Most tools can use multiple versions of the protocol, and the combination of versions they support will often cross the arbitrary TLS/SSL boundary. (Usually SSL 3.0 and at least TLS 1.0 and 1.1.) The exact protocol you'll be using at any given moment depends on the configuration of every tool that might interact with the system.

### Starting an SSL Connection

SSL always has two participants: a client, which initiates the connection, and a server, which accepts incoming connections. (These are flexible identities: Depending on how a system works, the same entity may act as a client sometimes and a server at other times.)

After a client starts the process, an SSL connection involves the following procedures:

* The client and server negotiate to figure out which cipher and protocol version to use.
* The server presents its certificate.
    * The client software validates that certificate, based on its knowledge of which CAs exist and are trustworthy. If it doesn't validate, the client bails.
* **Optionally,** the client can present a certificate of its own to the server, along with proof that it possesses the corresponding private key.
    * This only happens if the server explicitly requests "client authentication." Not all SSL connections require this; for example, most HTTPS sites on the web don't require client authentication.
* The client sends a temporary "session" encryption key to the server, encrypted so that only the owner of the server certificate can read it.
* Both client and server use that session key to encrypt all subsequent traffic in the connection.

### What an SSL Connection Gets You

After the connection starts, the two parties have the following tools and extra information:

* Both parties have access to an encrypted communication channel, which can't be eavesdropped on.
* The client knows it is talking to the rightful owner of the server certificate (since only the rightful owner could have decrypted that session key).
* The client knows that any metadata in the server certificate was validated by a trusted CA.
* The client can use any metadata in the server certificate to **authorize** the server. Some of this authorization may be simple and automatic, and some may require more consideration. As an example, consider what a web browser and its user do in a standard web HTTPS connection:
    * Web SSL certificates contain a list of domain names that are allowed to present that certificate. The web browser automatically checks for the domain name it contacted in that list. If it isn't included, the browser can refuse to let the user continue.
    * Certificates also list the name of the organization that was issued the certificate, and web browsers present that name to the user. (Usually behind a little padlock icon.) If the user checks that organization name and doesn't believe that it matches the rightful operator of the website they think they're visiting, they may choose to distrust and bail.
    * A website may ask for sensitive information that the user is only willing to share with certain trusted parties. If the user checks the organization name in the certificate and doesn't wish to share that information with that organization, they may decide not to provide it.
* If client authorization was requested and accepted, the server also has metadata about the client. In a reversal of the last point, the server can use that metadata to authorize the client. For example, it may apply extra protection to certain resources and decide that only clients with certain highly-trusted certificates can access them. This could be done by maintaining a list of allowed client names, or by looking for a certain token that was embedded in the client's certificate at the time that it was signed.


HTTPS
-----

