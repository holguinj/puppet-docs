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
### Boolean
### Regexp
### String
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

