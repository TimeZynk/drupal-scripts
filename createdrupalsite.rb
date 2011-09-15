#!/usr/bin/env ruby

require 'optparse'
require 'erb'
require 'mechanize'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = 'usage: createdrupalsite.rb [options]'

  options[:prefix] = nil
  opts.on('-p', '--prefix PREFIX', 'set site prefix') do |prefix|
    options[:prefix] = prefix
  end

  options[:domain] = 'tzapp.com'
  opts.on('-d', '--domain DOMAIN', 'set domain, default tzapp.com') do |domain|
    options[:domain] = domain
  end

  options[:site_name] = nil
  opts.on('-n', '--name SITE_NAME', 'set site name') do |site_name|
    options[:site_name] = site_name
  end

  opts.on('-h', '--help', 'Show this screen') do
    puts opts
    exit
  end
end

optparse.parse!

unless options[:prefix]
  puts optparse.help
  exit
end

class SiteBuilder
  attr_reader :site_prefix, :domain, :db_password

  def initialize(options)
    @site_prefix = options[:prefix]
    @domain = options[:domain]
    @db_password = %x<pwgen -c -n 12 1>.chomp
  end

  def settings
    settings_path = File.absolute_path('settings.php.erb', File.dirname(__FILE__))
    erb = ERB.new File.new(settings_path).read
    erb.result binding
  end

  def db_user
    @site_prefix
  end

  def hostname
    "#{@site_prefix}.#{@domain}"
  end

  def setup_database
    puts "Creating database \"#{@site_prefix}\""
    system "mysqladmin -u root -p create \"#{@site_prefix}\""

    puts "Creating DB user \"#{@site_prefix}\""
    system "echo \"GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON \\`#{@site_prefix}\\`.* TO '#{@site_prefix}'@'localhost' IDENTIFIED BY '#{@db_password}';\" | mysql -u root -p mysql"
  end

  def create_site_dir
    puts "Creating #{hostname}/settings.php"
    Dir.mkdir hostname
    settings_file = File.new "#{hostname}/settings.php", 'w'
    settings_file.write settings
    settings_file.chmod 0644
    Dir.mkdir "#{hostname}/files"
    File.chmod 0777, "#{hostname}/files"
  end

   def visit_install_page
#     agent = Mechanize.new
#     agent.follow_meta_refresh = :anywhere
#     page = agent.get("https://#{hostname}/install.php?profile=default&locale=en&op=do_nojs&id=1")
#     pp page
#     page = agent.get("https://#{hostname}/install.php?profile=default&locale=en&op=finished&id=1")
#     pp page
   end
end

builder = SiteBuilder.new options
builder.setup_database
builder.create_site_dir
builder.visit_install_page

