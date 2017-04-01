#!/usr/bin/ruby

# display configuration from yaml file
# usage examples : 
#   - get-config.rb mqtt/host
#   - get-config.rb mqtt/port
# 

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/")

require "main.rb"

arg=ARGV[0].split('/')

c=@config
arg.each do |v|
	c=c[v.to_sym]
end

puts c
