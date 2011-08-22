#!/usr/bin/env ruby
require 'redcarpet'
puts "<!DOCTYPE html>"
puts '<html><head><meta charset="UTF-8">'
puts '<style type="text/css">
body {
    font-family: Helvetica Neue;
    font-weight: 200;
}
h1, h2, h3, h4, h5 {
    font-family: Serifa Std;
}
puts </style>'
puts '</head><body>'
Dir.glob(ARGV[0] + '/**/*.markdown') do |f|
  puts Redcarpet.new(File.read(f)).to_html
end

puts "</body></html>"
