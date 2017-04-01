#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")

require "main.rb"
require 'mqtt'

pp @config
# pp @config[:mqtt]

# puts File.expand_path $0
