Introduction
------------

This rubygem provides a DSL for managing various service provider APIs:

* [Gandi](http://doc.rpc.gandi.net/) .

Release Process
---------------

Bump the `VERSION` in `lib/provider_dsl/gem_description.rb`. Only bump the last minor version if there are no changes that will break the executable for users, otherwise bump a major version. Then run the following command:

    rake release
