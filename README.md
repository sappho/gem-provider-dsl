Introduction
------------

This rubygem provides a DSL for managing various service provider APIs:

* [Gandi](http://doc.rpc.gandi.net/)
* [Google Cloud Platform](https://cloud.google.com/)

Gem Status
----------

Note that this gem is currently a work in progress. Do not use this code for production projects.

License
-------

This code is provided under the MIT License, see `LICENSE` for details.

Release Process
---------------

Bump the `VERSION` in `lib/provider_dsl/gem_description.rb`. Only bump the last minor version if there are no changes that will break the executable for users, otherwise bump a major version. Then run the following command:

    rake release
