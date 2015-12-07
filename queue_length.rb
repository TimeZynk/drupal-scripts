require 'beanstalk-client'
require 'uri'

beanstalk_url = ENV['BEANSTALK_URL'] || 'beanstalk://localhost/'
uri = URI.parse(beanstalk_url)
host_and_port = "#{uri.host}:#{uri.port || 11300}"

pool = Beanstalk::Pool.new([host_and_port])

stats = pool.stats()
printf(
    "Beanstalk STATS Ready: %d,\t Reserved: %d,\t Delayed: %d\n",
    stats["current-jobs-ready"],
    stats["current-jobs-reserved"],
    stats["current-jobs-delayed"]
)
