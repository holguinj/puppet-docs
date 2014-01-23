---
layout: default
title: "move this into guides"
---




Public Key Cryptography
-----

The term **public key cryptography** generally means a family of algorithms and practices for encrypting and verifying information.

A complete description of how public key crypto works is far outside the scope of this page, but since it's foundational for any SSL-related system, we present below a broad overview of its properties.

* In public key crypto, each participant possesses a _key pair,_ which consists of a _public key_ and a _private key._ These are both large, nearly-impossible-to-guess numbers, which are mathematically related to each other in a specific way.
    * Any public key has one (and only one) corresponding private key, and vice-versa.
    * The public key can and should be shared freely.
    * The private key must stay private. If a copy of it is stolen, the thief can impersonate the rightful owner until all other participants have stopped using and trusting the corresponding public key.
    * A private key can't be reverse-engineered from its corresponding public key. (Or at least, doing so isn't practical with current or foreseeable-future technology.)
* If you have the _public_ part of a given key pair, you can _encrypt_ a message so that it can only be decrypted by whoever possesses the corresponding _private_ key.
* If you have the _private_ part of a given key pair, you can _digitally sign_ a message, which means anyone possessing the corresponding _public_ key can:
    * Prove that whoever signed the message is (or was) actually in possession of that private key.
    * Determine whether the message was altered after the signature was made.

To be useful for real-world purposes, a public key crypto scheme must be combined with some other system that links known keypairs to some form of _identity._ (Otherwise, they're just big annoying numbers.) This can be a local registry (think handwritten phone book), a central registry (think DNS), a signature-based system (think driver's licence), or some combination of them.


Certificates and Public Key Infrastructure
-----

A public key infrastructure (PKI) is a way to associate public keys with trusted information about their owners. In other words, it serves the purpose described at the end of the previous section.

Once again, a complete description is outside the scope of this page ([the Wikipedia page on PKI][wiki_pki] may be a good starting place), but we will try to cover the basics below.

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
* The CA uses its key pair to craft a _self-signed certificate._ (That is, the signature is provided by the same key pair that the certificate describes.) This certificate's metadata states that the CA is allowed to sign new certificates.
* The CA certificate is distributed to other participants in the PKI. This is often done out-of-band as part of some bootstrapping process. (For example, the root CA certificates used by web browsers can be bundled with the executable and installed alongside it. Most modern operating systems also ship with root CA certs included.)

At this point, other participants can use the CA's certificate to verify signatures on any certificates that claim to be vetted by that CA. If the signature fails to validate, they will consider that certificate forged and decline to trust it.

### Certificate Signing Requests

Once the foundation of CA trust is established, participants can send certificate signing requests (CSRs) to the CA, via some formal, informal, or automated process.

A CSR contains the applicant's public key and any metadata that the applicant wants to have in their certificate. (In terms of content, it's just a certificate minus the CA signature.)

The CA can double-check this metadata, and perform any background checks it considers necessary. It will then choose whether or not to sign the request with its private key.

Signing the request will create a new certificate for the entity that requested it. That entity will then have to retrieve the certificate from the CA. Once they have it, they can present the certificate to other participants and use their private key to prove themselves as the certificate's rightful owner. Other participants can use the CA's signature to prove that the metadata in the certificate was vetted by that CA.

### Certificate Revocation Lists

Trusted certificates sometimes need to become un-trusted, often as a result of a security breach. To handle this, a CA will maintain a certificate revocation list (CRL), which contains the serial numbers of any certificates that should no longer be trusted.

Participants in the PKI should regularly retrieve a copy of each CA's CRL, and should double-check certificates against it when checking their validity.

### Certificate Lifespans

Each certificate has a period of time for which it is valid; before or after this timespan, the certificate should not be trusted. The validity period is assigned by the CA when signing the certificate.

When checking a certificate's validity, participants in a PKI should check also ensure that the certificate has not expired.


