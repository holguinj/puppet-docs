---
layout: default
title: "Future Language: The Collection Type"
canonical: "/puppet/latest/reference/future_collection_type.html"
---


Using the Collection Types in Parameter Declarations
===============================================

## The Array Type

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

