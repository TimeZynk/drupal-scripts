#!/usr/bin/env ruby

hostname = File.basename Dir.pwd

system "drush pm-enable -y permissions_api"
system "drush pm-disable -y comment"
system "drush pm-enable -y admin_menu admin_menu_toolbar po_re_importer devel css_injector"
system "drush pm-enable -y timezynk_basic_feature timezynk_intelliplan_feature"
system "drush variable-set -y site_frontpage tzuser"
system "drush variable-set -y menu_primary_links_source navigation"
