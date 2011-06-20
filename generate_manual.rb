#!/usr/bin/env ruby
require 'redcarpet'
puts "<!DOCTYPE html>"
puts '<html><head><meta charset="UTF-8"></head><body>'
Dir.glob(ARGV[0] + '/**/*.markdown') do |f|
  puts Redcarpet.new(File.read(f)).to_html
end

puts "</body></html>"
