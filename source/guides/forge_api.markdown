---
layout: default
swagger: /files/swagger/api/api-docs
title: Puppet Forge API
---
Puppet Forge API
==========================
* * *
The Puppet Forge API (hereafter referred to as the Forge API) enables you to write scripts and tools that interact with the Puppet Forge website, from customized module publishing to custom aggregations against module metadata. The Forge API provides you quick access to all the data on the Puppet Forge via a RESTful interface.

Tools such as the puppet module tool and librarian-puppet use the Forge API to query and install modules, and tools like Geppetto or Pulp leverage the API to solve development workflow challenges.

Interactive Demonstration
-------------------------
This interface provides an interactive demonstration of the Forge API, along with additional notes about the different endpoints and available parameters. You can use the web forms to craft a query and see the results immediately. 

{% include swagger_div.html %}

Current Version
---------------
The Forge API's current version is `v3`. It’s considered regression-stable, meaning that the returned data is guaranteed to match the schema described on this page, however, additional data may be added in the future and existing clients may ignore any properties they do not recognize.

The API currently exposes three resource types: Users, Modules, and Releases. Details for these resources, including available parameters and response schemas, can be found within the interactive UI above this section.

This version of the API does not currently support authentication or any of the operations that would normally require authentication, such as publishing, updating, or deleting modules.


Features
--------
* The API is accessed over HTTPS via the `forgeapi.puppetlabs.com` domain. All data is returned in JSON format.
* Blank fields are included as `null`.
* Nested resources will use an abbreviated representation. A link to the full representation for the resource will always be included.
* All timestamps are returned in ISO 8601 format: `YYYY-MM-DD HH:MM:SS ±HHMM`.
* The HTTP response headers include caching hints for [conditional requests](#conditional-requests).


Errors
------
The Puppet Forge API follows RFC 2616 and RFC 6585.

Error responses will be served with a `4xx` or `5xx` status code, and will be sent as a JSON hash with a `message` key, describing the cause of the failure.

{% highlight json %}
	{ "message": "Cannot parse request body as JSON" }
{% endhighlight %}

If the error has more specific causes (e.g. trying to update a User account with invalid data), an `errors` key will be provided containing a list of specific problems with the request.

{% highlight json %}
	{
	  "message": "Validation Failed",
	  "errors": [
	    {
	      "resource": "User",
	      "field": "username",
	      "code": "not_unique"
	    },
	    {
	      "resource": "User",
	      "field": "display_name",
	      "code": "missing"
	    }
	  ]
	}
{% endhighlight %}

User-Agent Required
-------------------
All API requests must include a valid User-Agent header. Requests with no User-Agent header will be rejected. The User-Agent header helps identify your application or library, so we can communicate with you if necessary. If your use of the API is informal or personal, we recommend using your username as the header.

User-Agent headers are a list of one or more product descriptions, generally taking the form:

	<name-without-spaces>/<version> (comments)

For example, the following are all useful User-Agent values:

*	`MyApplication/0.0.0 Her/0.6.8 Faraday/0.8.8 Ruby/1.9.3-p194 (i486-linux)`
*	`My-Library-Name/1.2.4`
*	`myusername`


Conditional Requests
--------------------
Most responses return a Last-Modified header, though some responses will also return an ETag header. You can use the values of these headers to make subsequent requests to those resources using the If-Modified-Since and If-None-Match headers. If the resource has not changed, the server will return a `304 Not Modified`.

{%highlight console %}
$ curl -I https://forgeapi.puppetlabs.com/v3/users/puppetlabs
HTTP/1.1 200 OK
Server: nginx/1.2.1
Date: Fri, 01 Nov 2013 00:50:13 GMT
Content-Type: application/json;charset=utf-8
Content-Length: 252
Connection: keep-alive
Status: 200 OK
X-Frame-Options: sameorigin
X-XSS-Protection: 1; mode=block
Cache-Control: public, must-revalidate
Last-Modified: Mon, 12 Nov 2012 14:51:00 GMT
X-Node: forgeapi02
X-Revision: b81ba451f67a95cfd38312093c158a6fdc919b46

$ curl -I https://forgeapi.puppetlabs.com/v3/users/puppetlabs -H "If-Modified-Since: Mon, 12 Nov 2012 14:51:00 GMT"
HTTP/1.1 304 Not Modified
Server: nginx/1.2.1
Date: Fri, 01 Nov 2013 00:51:28 GMT
Connection: keep-alive
Status: 304 Not Modified
X-Frame-Options: sameorigin
X-XSS-Protection: 1; mode=block
Cache-Control: public, must-revalidate
Last-Modified: Mon, 12 Nov 2012 14:51:00 GMT
X-Node: forgeapi02
X-Revision: b81ba451f67a95cfd38312093c158a6fdc919b46
{% endhighlight %}