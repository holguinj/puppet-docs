---
layout: default
title: "Future Language: Parameter Types"
canonical: "/puppet/latest/reference/future_parameter_types.html"
---

## Puppet Types

### Integer

Matches: whole numbers of any size within the limits of available memory.
Required Parameters: None.
Optional Parameters: minimum value, maximum value.

Examples:

* `Integer` -- any integer
* `Integer[0]` -- any integer greater than or equal to 0
* `Integer[2, 8]` -- any integer from 2 to 8, inclusive

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
### Hash


## Catalog Types

### Resource
### Class


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

