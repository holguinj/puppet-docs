---
layout: default
title: "Future Language: String Type"
canonical: "/puppet/latest/reference/future_string_type.html"
---


Using the String Type in Parameter Declarations
===============================================

## Validating String Length

The `String` type accepts one or two optional parameters: minimum length and maximum length. If you provide only one parameter, it will be treated as the minimum length. For example:

* `String` --- matches a string of any length.
* `String[6]` --- matches a string with *at least* 6 characters.
* `String[6, 8]` --- matches a string with at least 6 and at most 8 characters.

## Validating Regex With the `Pattern` Type

You can also validate strings against a regular expression by using the `Pattern` type, which requires at least one regular expression as a parameter. For example:

* `Pattern[/foo/]` --- matches a string containing "foo".
* `Pattern[/foo/, /bar/]` --- matches a string that contains "foo" or "bar".

There are a few limitations to keep in mind with the `Pattern` type:

* Additional options like `i` (case insensitive) are currently not supported.
* Capture groups are not supported.
* `Pattern` is a subtype of `String`, so it will only match strings.

## Validating From a List with the `Enum` Type

You can use the `Enum` type to check that a string exactly matches one of several options (provided as parameters). For example:

* `Enum['stopped', 'running']` --- matches a string that is either `'stopped'` or `'running'`.
* `Enum['true', 'false']` --- matches a string that is either `'true'` or `'false'`. Will not match `true` or `false` (without quotes).

You must provide at least one parameter, but this type is only really useful with two or more options. The `Enum` type **only validates strings**, not booleans (`true` or `false`), integers, or any other type.
