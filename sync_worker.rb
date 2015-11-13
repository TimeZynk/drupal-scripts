require 'stalker'
include Stalker

MAX_JOBS = 20
$num_jobs = 0

job 'intellitime.sync' do |args|
  users = args['users'].join(',')
  system %Q<drush "--root=#{args['root']}" "--uri=#{args['site']}" intellitime-sync "#{users}">

  # Restart periodically to avoid zombie processes from the shell
  $num_jobs += 1
  if $num_jobs >= MAX_JOBS
    exit
  end
end
