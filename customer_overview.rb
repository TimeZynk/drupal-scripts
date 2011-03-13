#!/usr/bin/env ruby

require 'yajl'
require 'optparse'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "usage: customer_overview.rb -r <drupal root> [-s <site suffix>]"
  
  options[:drupal_root] = nil
  opts.on('-r', '--drupal-root PATH', 'Drupal root directory') do |path|
    options[:drupal_root] = path
  end
  
  options[:site_suffix] = 'tzapp.com'
  opts.on('-s', '--site-suffix SUFFIX', 'Site suffix, default tzapp.com') do |suffix|
    options[:site_suffix] = suffix
  end
  
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

if not options[:drupal_root] or not File.directory?(options[:drupal_root] + '/sites')
  puts "invalid drupal root: #{options[:drupal_root]}\n" << optparse.help
  exit
end

class Stats
  GREY = -10
  RED = 0
  YELLOW = 10
  GREEN = 20

  attr_accessor :red, :yellow, :green
  def initialize(name)
    @name = name
    @grey = 0
    @red = 0
    @yellow = 0
    @green = 0
  end
  
  def add(status)
    if status == GREY
      @grey += 1
    elsif status == RED
      @red += 1
    elsif status == YELLOW
      @yellow += 1
    else
      @green += 1
    end
  end
  
  def to_html
    sum = @grey + @red + @yellow + @green
    %Q|<tr><td class="name">#{@name}</td><td class="number">#{@grey}</td><td class="number">#{@red}</td><td class="number">#{@yellow}</td><td class="number">#{@green}</td><td class="number">#{sum}</td></tr>|
  end
end

totals = Stats.new('<strong>Total</strong>')

title = "Customer Overview #{Time.now.strftime('%Y-%m-%d %H:%M')}"
style = <<-endofstyle
body {
  font-family: sans-serif;
}
h1 {
  font-family: Helvetica Neue;
  font-weight: 100;
  font-size: 20pt;
}
.name {
  padding-right: 2em;
}
.number {
  text-align: center;
}
th {
  text-align: left;
}
endofstyle

puts "<html><head><title>#{title}</title><style>#{style}</style></head><body>"
puts "<h1>#{title}</h1>"
puts "<table><thead><th>Customer</th><th>Grey</th><th>Red</th><th>Yellow</th><th>Green</th><th>Total</th></thead>"
puts "<tbody>"

# Look through drupal root
Dir.glob("#{options[:drupal_root]}/sites/*.#{options[:site_suffix]}") do |filename|
  site = File.basename filename
  site_status_json = %x<drush "--root=#{options[:drupal_root]}" "--uri=#{site}" tzuser-overview>
  site_totals = Stats.new(site)
  
  Yajl::Parser.parse(site_status_json).each do |entry|
  	totals.add entry['status']
	site_totals.add entry['status']
  end
  
  puts site_totals.to_html
end

puts totals.to_html
puts "</tbody></table></body></html>"