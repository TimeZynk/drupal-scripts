#!/usr/bin/env ruby

require 'optparse'
require 'stalker'

class Scanner
  def parse_options
    @options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "usage: schedule_sync.rb -r <drupal root> [-s <site suffix>]"

      @options[:drupal_root] = nil
      opts.on('-r', '--drupal-root PATH', 'Drupal root directory') do |path|
        @options[:drupal_root] = path
      end

      @options[:site_suffix] = 'tzapp.com'
      opts.on('-s', '--site-suffix SUFFIX', 'Site suffix, default tzapp.com') do |suffix|
        @options[:site_suffix] = suffix
      end

      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        return false
      end
    end

    optparse.parse!

    if not @options[:drupal_root] or not File.directory?(@options[:drupal_root] + '/sites')
      puts "invalid drupal root: #{@options[:drupal_root]}\n" << optparse.help
      return false;
    end

    return true
  end


  def drush(site, command)
    output = %x(drush "--root=#{@options[:drupal_root]}" "--uri=#{site}" #{command} 2>&1)
    if $? == 0
      output.strip
    else
      puts site + ': error when running drush'
      false
    end
  end

  def check_pending_sync
    # Look through drupal root
    Dir.glob("#{@options[:drupal_root]}/sites/*.#{@options[:site_suffix]}") do |filename|
      site = File.basename filename
      check_site_sync site
    end
  end

  def check_site_sync(site)
    intelliplan_enabled = drush site, "php-eval 'print(module_exists(\"tzintellitime\"));'"
    return unless intelliplan_enabled === '1'

    sync_partition = drush site, 'intellitime-partition'
    pending_users = sync_partition.split ';'
    pending_users.each_with_index do |users, index|
      schedule_sync site, users.split(','), index*2
    end
  end

  def schedule_sync(site, users, delay)
    puts site + ': scheduling users ' + users.join(', ') + ' with delay ' + delay.to_s + 's'
    Stalker.enqueue 'intellitime.sync', {
        :root => @options[:drupal_root], :site => site, :users => users
      }, {
        :ttr => 180,
        :delay => delay
      }
  end

end

scanner = Scanner.new
exit unless scanner.parse_options
scanner.check_pending_sync
