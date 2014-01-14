module PuppetDocs
  module Reference
    module Type
      require 'json'
      require 'erb'

      def build_page(typejson)
        typedocs = JSON.load(typejson)
        header = <<EOT
---
layout: default
title: "Type Reference"
canonical: "/references/latest/type.html"
munge_header_ids: false
toc: false
---

EOT

        generated_at = "> **NOTE:** This page was generated from the Puppet source code on #{Time.now.to_s}"
        footer = generated_at
        preamble = <<EOT
#{generated_at}

## About Resource Types

### Built-in Types and Custom Types

This is the documentation for the _built-in_ resource types and providers, keyed
to a specific Puppet version. (See sidebar.) Additional resource types can be
distributed in Puppet modules; you can find and install modules by browsing the
[Puppet Forge](http://forge.puppetlabs.com). See each module's documentation for
information on how to use its custom resource types.

### Declaring Resources

To manage resources on a target system, you should declare them in Puppet
manifests. For more details, see
[the resources page of the Puppet language reference.](/puppet/latest/reference/lang_resources.html)

You can also browse and manage resources interactively using the
`puppet resource` subcommand; run `puppet resource --help` for more information.

### Namevars and Titles

All types have a special attribute called the *namevar.* This is the attribute
used to uniquely identify a resource _on the target system._ If you don't
specifically assign a value for the namevar, its value will default to the
_title_ of the resource.

Example:

    file { '/etc/passwd':
      owner => root,
      group => root,
      mode  => 644
    }

In this code, `/etc/passwd` is the _title_ of the file resource; other Puppet
code can refer to the resource as `File['/etc/passwd']` to declare
relationships. Because `path` is the namevar for the file type and we did not
provide a value for it, the value of `path` will default to `/etc/passwd`.

### Attributes, Parameters, Properties

The *attributes* (sometimes called *parameters*) of a resource determine its
desired state.  They either directly modify the system (internally, these are
called "properties") or they affect how the resource behaves (e.g., adding a
search path for `exec` resources or controlling directory recursion on `file`
resources).

### Providers

*Providers* implement the same resource type on different kinds of systems.
They usually do this by calling out to external commands.

Although Puppet will automatically select an appropriate default provider, you
can override the default with the `provider` attribute. (For example, `package`
resources on Red Hat systems default to the `yum` provider, but you can specify
`provider => gem` to install Ruby libraries with the `gem` command.)

Providers often specify binaries that they require. Fully qualified binary
paths indicate that the binary must exist at that specific path, and
unqualified paths indicate that Puppet will search for the binary using the
shell path.

### Features

*Features* are abilities that some providers may not support. Generally, a
feature will correspond to some allowed values for a resource attribute; for
example, if a `package` provider supports the `purgeable` feature, you can
specify `ensure => purged` to delete config files installed by the package.

Resource types define the set of features they can use, and providers can
declare which features they provide.

----------------

EOT

        sorted_type_list = typedocs.keys.sort
        custom_toc = %q{
<nav id="page-nav" class="in-page">
<ol class="toc" style="-webkit-column-width: 13em; -webkit-column-gap: 1.5em; -moz-column-width: 13em; -moz-column-gap: 1.5em; column-width: 13em; column-gap: 1.5em;">
} + sorted_type_list.collect{|name| %q[<li class="toc-lv2"><a href="#] + name.gsub('_','') + %q[ "onclick="_gaq.push(['_trackPageview' ,'/']);">] + name + %q[</a></li>] }.join("\n") + %q{
</ol></nav>} + "\n\n"
        # Admission: I'm being lazy about generating the header IDs, since the type
        # names are already downcased, have no spaces, and the only character the ID
        # generator will remove is the underscore.

        # Other admission: 13em width was pulled out of a butt b/c it appears to
        # leave enough room for two digits, a dot, a space, and
        # nagios_servicedependency.

        all_type_docs = sorted_type_list.collect{|name|
          docs_for_this_type(name, typedocs[name])
        }.join("\n\n---------\n\n")

        # And return:
        header + custom_toc + preamble + all_type_docs + "\n\n" + footer
      end

      def docs_for_this_type(name, this_type)
        sorted_attribute_list = this_type['attributes'].keys.sort {|a,b|
          # Float namevar to top and ensure to second-top
          if this_type['attributes'][a]['namevar']
            -1
          elsif this_type['attributes'][b]['namevar']
            1
          elsif a == 'ensure'
            -1
          elsif b == 'ensure'
            1
          else
            a <=> b
          end
        }
        sorted_feature_list = this_type['features'].keys.sort
        longest_attribute_name = sorted_attribute_list.collect{|attr| attr.length}.max

        ERB.new(File.read(File.dirname(__FILE__) + '/type_template.erb'), nil, '-').result(binding)
      end


      module_function :build_page
      module_function :docs_for_this_type

    end
  end
end