require 'stalker'
include Stalker

job 'intellitime.sync' do |args|
  users = args['users'].join(',')
  system %Q<drush "--root=#{args['root']}" "--uri=#{args['site']}" intellitime-sync "#{users}">
end
