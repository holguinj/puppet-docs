---
layout: default
title: "Facter 2.0: Frequently Asked Questions"
---

Frequently Asked Questions
==========================

### How can I make a new fact based on a shell command or script?

Facter's API makes it very easy to write new facts in Ruby that use the shell to do all the heavy lifting. Try modeling your fact on [this example](fact_anatomy.html#example-minimal-fact-that-relies-on-a-single-shell-command). If you'd rather not use Ruby at all, you can write an [external fact](custom_facts.html#external-facts) in the language of your choice.


### Where should I put custom/external facts?


