#!/usr/bin/env ruby

require 'beanstalk-client'
require 'uri'
require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "usage: queue_length.rb [-l <queue limit>]"

  options[:limit] = 0
  opts.on('-l', '--limit LIMIT', 'Queue length limit to test for, default 0') do |limit|
    options[:limit] = [0, limit.to_i].max
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
  end
end

exit unless optparse.parse!

beanstalk_url = ENV['BEANSTALK_URL'] || 'beanstalk://localhost/'
uri = URI.parse(beanstalk_url)
host_and_port = "#{uri.host}:#{uri.port || 11300}"

pool = Beanstalk::Pool.new([host_and_port])

stats = pool.stats_tube('intellitime.sync')
printf(
    "Beanstalk STATS Ready: %d,\tReserved: %d,\tDelayed: %d",
    stats["current-jobs-ready"],
    stats["current-jobs-reserved"],
    stats["current-jobs-delayed"]
)

if stats["current-jobs-ready"] > options[:limit]
    printf(
        "\tExceeds limit: %d\n",
        stats["current-jobs-ready"],
        options[:limit]
    )
    exit 1
else
    printf("\n")
end
