require 'stalker'
include Stalker

MAX_JOBS = 20
$num_jobs = 0
$last_run = Time.now.to_f

job 'intellitime.sync' do |args|
  now = Time.now.to_f
  puts "Idle for " + (now - $last_run).to_s + " seconds"

  users = args['users'].join(',')
  system %Q<drush "--root=#{args['root']}" "--uri=#{args['site']}" intellitime-sync "#{users}">

  # Restart periodically to avoid zombie processes from the shell
  $num_jobs += 1
  if $num_jobs >= MAX_JOBS
    exit
  end

  # Update last run timestamp
  $last_run = Time.now.to_f
end
