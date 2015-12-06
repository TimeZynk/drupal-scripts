require 'stalker'
require 'timeout'
include Stalker

MAX_JOBS = 20
$num_jobs = 0
$last_run = Time.now.to_f
$child = nil

job 'intellitime.sync' do |args|
  now = Time.now.to_f
  printf("Idle for %d seconds\n", (now - $last_run))

  users = args['users'].join(',')
  $child = spawn('drush', "--root=#{args['root']}", "--uri=#{args['site']}", 'intellitime-sync', "#{users}")
  Process::wait($child)
  $child = nil

  # Update last run timestamp
  $last_run = Time.now.to_f

  # Restart periodically to avoid zombie processes from the shell
  $num_jobs += 1
  if $num_jobs >= MAX_JOBS
    exit
  end
end

error do |e, job, args|
  puts "Caught error, terminating child processes"
  if $child.nil?
    exit
  else
    printf("Sending SIGTERM to %d\n", $child)
    Process::kill("TERM", $child)
    begin
      Timeout::timeout(5) do
        Process::wait($child)
        $child = nil
      end
    rescue Timeout::Error
      unless $child.nil?
        printf("Sending SIGKILL to %d\n", $child)
        Process.kill("KILL", $child)
        Process::wait($child)
      end
    end
  end
  exit
end
