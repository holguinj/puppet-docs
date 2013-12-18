---
layout: default
title: Complete Resource Example
---

Complete Resource Example
=========================

This document walks through the definition of a very simple resource type and one provider. We'll build the resource up slowly, and the provider along with it. See [Custom Types](./custom_types.html) and [Provider Development](/guides/provider_development.html) for more information on the individual classes.  As with creating [Custom Facts](/guides/custom_facts.html) and [Custom Functions](/guides/custom_functions.html), these examples involve Ruby programming.

* * *

Resource Creation
-----------------

Nearly every resource needs to be able to be created and
destroyed, and resources have to have names, so we'll start with
those two features. Puppet's property support has a helper method
called `ensurable` that handles modeling creation and destruction; it
creates an `ensure` property and adds `absent` and `present` values for
it, which in turn require three methods on the provider, `create`,
`destroy`, and `exists?`. Here's the first start to the resource.  We're
going to create one called 'file' --- this is an example of how we'd
create a resource for something Puppet already has.  You can see
how this would be extensible to handle one of your own ideas:

    Puppet::Type.newtype(:file) do
        @doc = "Manage a file (the simple version)."

        ensurable

        newparam(:name) do
            desc "The full path to the file."
        end
    end

Here we have provided the resource type name (it's `file`), a simple
documentation string (which should be in [Restructured Text](http://en.wikipedia.org/wiki/ReStructuredText) format), a parameter for the name of the file, and we've used the ensurable method to say that our file is both createable and destroyable.

To see how we would use this on the provider side, let's look at a simple provider:

    Puppet::Type.type(:file).provide(:posix) do
        desc "Normal Unix-like POSIX support for file management."

        def create
            File.open(@resource[:name], "w") { |f| f.puts "" } # Create an empty file
        end

        def destroy
            File.unlink(@resource[:name])
        end

        def exists?
            File.exists?(@resource[:name])
        end
    end

Here you can see that the providers use a different way of specifying
their documentation, which is not something that has been unified in Puppet
yet.

In addition to the docs and the provider name, we
provide the three methods that the `ensure` property requires. You
can see that in this case we're just using Ruby's built-in File
abilities to create an empty file, remove the file, or test whether
the file exists.

Let's enhance our resource somewhat by adding the ability to
manage the file mode.  Here's the code we need to add to the resource:

    newproperty(:mode) do
        desc "Manage the file's mode."

        defaultto "640"
    end

Notice that we're specifying a default value, and that it is a
string instead of an integer (file modes are in octal, and most of
us are used to specifying integers in decimal). You can pass a
block to defaultto instead of a value, if you don't have a simple
value.  (For more about blocks, see the Ruby language documentation).

Here's the code we need to add to the provider to understand modes:

    def create
        File.open(@resource[:name], "w") { |f| f.puts "" } # Create an empty file
        # Make sure the mode is correct
        should_mode = @resource.should(:mode)
        unless self.mode == should_mode
            self.mode = should_mode
        end
    end

    # Return the mode as an octal string, not as an integer.
    def mode
        if File.exists?(@resource[:name])
            "%o" % (File.stat(@resource[:name]).mode & 007777)
        else
            :absent
        end
    end

    # Set the file mode, converting from a string to an integer.
    def mode=(value)
        File.chmod(Integer("0" + value), @resource[:name])
    end

Note that the getter method returns the value, it doesn't attempt to
modify the resource itself.  Also, when the setter gets passed the value
it is supposed to set; it doesn't attempt to figure out the
appropriate value to use.  This should always be true of how providers are implemented.

Also notice that the `ensure` property, when created by the
`ensurable` method, behaves differently because it uses methods for creation
and destruction of the file, whereas normal properties use getter
and setter methods. When a resource is being created, Puppet
expects the `create` method (or, actually, any changes done within
ensure) to make any other necessary changes. This is because most
often resources are created already configured correctly, so it
doesn't make sense for Puppet to test it manually (e.g., useradd
support is set up to add all specified properties when useradd is
run, so usermod doesn't need to be run afterward).

You can see how the `absent` and `present` values are defined by
looking in the property.rb file; here's the most important
snippet:

    newvalue(:present) do
        if @resource.provider and @resource.provider.respond_to?(:create)
            @resource.provider.create
        else
            @resource.create
        end
        nil # return nil so the event is autogenerated
    end

    newvalue(:absent) do
        if @resource.provider and @resource.provider.respond_to?(:destroy)
            @resource.provider.destroy
        else
            @resource.destroy
        end
        nil # return nil so the event is autogenerated
    end

There are a lot of other options in creating properties,
parameters, and providers, but this should provide a
decent starting point.

See Also
--------

-   [Provider Development](./provider_development.html)
-   [Creating Custom Types](./custom_types.html)




