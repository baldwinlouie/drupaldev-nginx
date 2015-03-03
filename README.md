#DrupalDev nginx

This is a fork that works with Ubuntu 14.04 and the updated Php5.5 packages.  __This fork is more stripped down than the original.__  I've removed things like Solr, XPROF to get it working.  Will enhance in the future.

[Support Mike Bell on Gittip](https://www.gittip.com/mikebell/)

Vagrant configuration for Drupal Development. Supports Drupal 6/7/8. Drush installed via [Drush] (https://github.com/baldwinlouie/puppet-drush).  This can be configured to install any version of Drush using composer and Drush's git repository.

Need Help? Consult the [wiki](https://github.com/mikebell/drupaldev-nginx/wiki) first before submitting an issue.

#Tools
1. Easier handling of vhosts and dbs (see example.yaml)
2. Drush

#Dependencies
* Xcode with Command Line Tools installed
* Vagrant - http://www.vagrantup.com/
* VirtualBox - https://www.virtualbox.org/
* Librarian Puppet - https://github.com/rodjek/librarian-puppet
* Pupppet Gem - `gem install puppet`

#Install

1. Clone Me
2. `cd drupaldev-nginx`
3. `librarian-puppet install`
3. `mkdir sites`
4. `cp hieradata/example.yaml hieradata/sites.yaml`
5. Amend hieradata/sites.yaml as required to desired server/virtualhost name and db details
6. `vagrant up`

#VM Info
* Default IP 192.168.99.10, but this can be changed in Vagrantfile
* Sites built as *.drupal.dev (use dnsmasq).
* Ubuntu 14.04, Php 5.5.
* Mysql root password: drupaldev
