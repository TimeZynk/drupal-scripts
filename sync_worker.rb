require 'stalker'
require 'timeout'
require 'prometheus/client'
require 'prometheus/client/push'
include Stalker

MAX_JOBS = 100
$num_jobs = 0
$last_run = Time.now.to_f
$child = nil

$prometheus = Prometheus::Client.registry
$idle_seconds = $prometheus.counter(:idle_seconds, 'Number of idle seconds between jobs')
$job_age = $prometheus.gauge(:job_age_seconds, 'Age of current job')
$synced_users = $prometheus.counter(:synchronized_users, 'Number of synchronized_users')
$timeouts = $prometheus.counter(:timeouts, 'Number of timeouts')
$processed_jobs = $prometheus.counter(:processed_jobs, 'Number of processed jobs')
$pushgateway = Prometheus::Client::Push.new('sync-worker', ENV['WORKER_NAME'], ENV['PUSHGATEWAY_URL'] || 'http://pushgateway:9091')

job 'intellitime.sync' do |args|
  now = Time.now.to_f
  idle = (now - $last_run)
  age = (now - (args['ts'] || now))

  printf("Idle for %d seconds. Job age %d seconds.\n", idle, age)

  site = args['site']
  tags = {:site => site}

  $idle_seconds.increment(tags, idle)
  $timeouts.increment(tags, 0)
  $processed_jobs.increment(tags)
  $job_age.set(tags, age)

  users = args['users'].join(',')
  $child = spawn('drush', "--root=#{args['root']}", "--uri=#{args['site']}", 'intellitime-sync', "#{users}")
  Process::wait($child)
  $child = nil

  $synced_users.increment(tags, args['users'].length)
  begin
    $pushgateway.add($prometheus)
  rescue StandardError => error
    puts error.inspect
  end

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
  site = args['site']
  tags = {:site => site}

  begin
    $timeouts.increment(tags, 1)
    $pushgateway.add($prometheus)
  rescue StandardError => error
    puts error.inspect
  end

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
