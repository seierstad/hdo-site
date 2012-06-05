Prototype for holderdeord.no.

[![Build Status](https://secure.travis-ci.org/holderdeord/hdo-site.png)](http://travis-ci.org/holderdeord/hdo-site)

Development dependencies
========================

- Ruby 1.9.2 or higher
- GEM Bundler (ruby-bundler)
- MySQL client and headers (libmysqlclient-dev)
- LibXML headers (libxml2-dev)
- LibXSLT headers (libxslt-dev)
- SQLite headers (libsqlite3-dev)
- Rails

Getting started:
================

    $ git clone git://github.com/holderdeord/hdo-site.git
    $ cd hdo-site
    $ sudo bundle install
    $ rake db:setup
    $ bundle exec rails server

TODO: Add something about importing data here.
