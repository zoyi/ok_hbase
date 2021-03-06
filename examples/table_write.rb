#!/usr/bin/env ruby
#
# perf_read.rb - basic read perf test

$:.unshift File.expand_path('../../lib', __FILE__)
$stdout.sync = true

require 'awesome_print'
require 'ok_hbase'
require 'optparse'
require 'logger'

$options = {}
$logger = Logger.new(STDOUT)
$logger.formatter = proc { |severity, datetime, progname, msg| "#{datetime} #{severity}: #{msg}\n" }
$logger.level = Logger::DEBUG

def usage(error=nil)
  puts "Error: #{error}\n\n" if error
  puts $optparse
  exit 1
end

def get_connection
  $logger.debug 'Setting up connection'


  $logger.debug "Connecting to #{$options[:host]}"
  OkHbase::Connection.new(
      auto_connect: true,
      host: $options[:host],
      port: $options[:port],
      timeout: $options[:timeout]
  )
end

def create_table(table, conn)
  if table.nil?
    $logger.fatal 'Must specify a table'
    return nil
  end
  $logger.debug "Get instance for table #{table}"
  if conn.tables.include? table
    OkHbase::Table.new(table, conn)
  else
    conn.create_table(table, d: {})
  end
end


def main()
  $optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options]"

    $options[:host] = 'localhost'
    $options[:port] = 9090
    $options[:timeout] = 10

    opts.on('-h', '--help', 'Display this help') do
      usage
    end

    opts.on('-H', '--host HOST', "host or ip address where thrift server is running, defaults to #{$options[:host]}") do |host|
      $options[:host] = host
    end

    opts.on('-t', '--table TABLE', 'hbase table name') do |table|
      $options[:table] = table
    end

    opts.on('-p', '--port PORT', "port number of thrift server, defaults to #{$options[:port]}") do |port|
      $options[:port] = port.to_i
    end

    opts.on('--timeout TIMEOUT', "connect timeout, defaults to #{$options[:timeout]}") do |timeout|
      $options[:timeout] = timeout.to_i
    end

  end

  usage "You didn't specify any options" if not ARGV[0]

  $optparse.parse!

  usage "You didn't specify a table" if not $options[:table]

  connection = get_connection()
  table = create_table($options[:table], connection)

  ('a'..'zzz').each_with_index do |row_key, index|
    $logger.debug "wrote row: #{row_key}"
    table.put(row_key, {'d:row_number' => "#{index+1}", 'd:message' => "this is row number #{index+1}"})
    $logger.debug "wrote row: #{row_key}"
  end
end

main() if __FILE__ == $0
