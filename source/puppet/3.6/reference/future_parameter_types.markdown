---
layout: default
title: "Future Language: Parameter Types"
canonical: "/puppet/latest/reference/future_parameter_types.html"
---

## Puppet Types

* Types. Got a lot of them. Some are concrete, some are abstract. Got a couple of collection types, too.
* Most of them take a set of parameters. Sometimes the parameters are required, sometimes they're optional.
* Optional parameters have to be given in order. If you want to "skip" the first optional parameter, you can sort of do that with `default`.

### Integer

Matches: whole numbers of any size within the limits of available memory. The `default` minimum and maximum values are `-Infinity` and `Infinity`, respectively.
Required Parameters: None.
Optional Parameters: minimum value, maximum value.

Examples:

* `Integer` -- matches any integer.
* `Integer[0]` -- matches any integer greater than or equal to 0
* `Integer[default, 0]` -- matches any integer less than or equal to 0.
* `Integer[2, 8]` -- matches any integer from 2 to 8, inclusive

### Float

Matches: floating point numbers within the limitations of Ruby's [Float class](http://www.ruby-doc.org/core-2.1.2/Float.html).
Required Parameters: None.
Optional Parameters: minimum value, maximum value.

Examples:

* `Float` -- any integer
* `Float[1.6]` -- any floating point number greater than or equal to 1.6
* `Float[1.6, 3.501]` -- any floating point number from 1.6 to 3.501, inclusive

### Boolean

Matches: `true` or `false`
Required Parameters: None.
Optional Parameters: None.

### Regexp

Matches: regular expressions. Not to be confused with the `Pattern` type, which matches strings.
Required Parameters: None.
Optional Parameters: Accepts a regex pattern for exact comparison.

Examples:

* `Regexp` -- matches any regular expression.
* `Regexp[/foo/]` -- matches the regular expression `/foo/` only

### String

Matches: strings.
Required Parameters: none.
Optional Parameters: minimum length, maximum length.

For more details on String and its subtypes `Pattern` and `Enum`, see the [String Parameter Type](future_string_type.html) page.

### Array

Matches: arrays.
Required Parameters: none.
Optional Parameters: type, minimum size, maximum size.

Examples:

* `Array` -- matches an array of any type or length.
* `Array[String]` -- matches an array of any size that contains only strings.
* `Array[Integer, 6]` -- matches an array containing at least six integers.
* `Array[Float, 6, 12]` -- matches an array containing at least six and at most 12 floating-point numbers.
* `Array[ Variant[String, Integer] ]` -- matches an array of any size that contains only strings and/or integers.
* `Array[Any, 2]` -- matches an array containing at least two elements, no matter what type those elements are.

### Hash

Matches: hash maps.
Required Parameters: none.
Optional Parameters: key type, value type, minimum size, maximum size.

Examples:

* `Hash` -- matches any hash map.
* `Hash[String]` -- matches any hash map that uses only strings as keys.
* `Hash[Integer, String]` -- matches a hash map that uses integers for keys and strings for values.
* `Hash[Integer, String, 1]` -- same as above, but requires a non-empty hash map.
* `Hash[Integer, String, 1, 8]` -- same as above, but with a maximum size of eight key-value pairs.

## Catalog Types

<!-- ### Resource -->

<!-- Matches: a Puppet resource. -->
<!-- Required Parameters: none. -->
<!-- Optional Parameters: resource type, any number of resource names. -->

<!-- Examples: -->

<!-- * `Resource` -- matches any Puppet resource. -->
<!-- * `Resource[File]` -- matches any file resource. -->
<!-- * `Resource[File, 'httpd.conf']` -- matches a file resource named `'httpd.conf'`. -->
<!-- * `Resource[File, 'httpd.conf', 'apache2.conf']` -- matches a file resource named `'httpd.conf'` **or** `'apache2.conf'`. -->

## Abstract Types

### Collection; a parent type of Array and Hash
### Scalar; a parent type of all single valued data types (Integer, Float, String, Boolean, Regexp)
### Numeric; the parent type of all numeric data types (Integer, Float)
### CatalogEntry; the parent type of all types that are included in a Puppet Catalog
### Data; a parent type of all kinds of general purpose "data" (Scalar and Array of Data, and Hash with Scalar key and Data values).
### Tuple; an Array where each slot is typed individually
### Struct; a Hash where each entry is individually named and typed
### Optional; either Undef or a specific type
### Variant; one of a selection of types
### Enum; an enumeration of strings
### Pattern; an enumeration of regular expression patterns
### Any; the parent type of all types
