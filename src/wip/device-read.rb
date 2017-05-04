#!/usr/bin/ruby

# read device.yaml
require 'pp'
require 'yaml'

def parse_yaml file

	begin
	  	return YAML.load(File.open(file))
	rescue ArgumentError => e
	  puts "Could not parse YAML file (#{file}: #{e.message}"
	  exit 0
	end

end

class ViessmanCommand

	def initialize name, opts
		@name=name
		@opts=opts
	end

	def self.to_hex val, digits=4
		sprintf("0x%0#{digits}X", val)
	end

	# mandatory field
	def addr
		throw "mandatory field 'addr' for #{@name} command" unless  @opts.key? :addr
		return @opts[:addr]
	end

	def type
		throw "mandatory field 'type' for #{@name} command" unless  @opts.key? :type
		return @opts[:type][0]
	end

	def mode default=:ro
		throw "mandatory field 'mode' for #{@name} command" unless  @opts.key? :type
		return @opts[:type][1]
	end

	def mult default=1
		return @opts[:mult] if @opts.key? :mult
		return default
	end

	# commands categories
	def cat default=[]
		return @opts[:cat] if @opts.key? :cat
		return default
	end
	alias category cat

	def unit default=''
		return @opts[:unit] if @opts.key? :unit
		return default
	end

	def description default=''
		return @opts[:description] if @opts.key? :description
		return default
	end

	def path default=nil
		throw "mandatory field 'path' for #{@name} command" unless  @opts.key? :type
		return @opts[:path] if @opts.key? :path
	end

	def in_range? value
		return self.range.include? value
	end

	def range default=[]
		return Range.new(@opts[:range][0], @opts[:range][1]) if @opts.key? :range
		return default
	end

	# protected

end

class Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end

	def _symbolize(obj, k=nil)
		
		return obj if k=='description'
		return obj if obj.is_a? Fixnum

		return obj.inject({}){|memo,(k,v)| memo[k.to_sym] =  _symbolize(v, k); memo} if obj.is_a? Hash
		return obj.inject([]){|memo,v    | memo           << _symbolize(v, k); memo} if obj.is_a? Array

		if obj.is_a?(String) && obj.tr(' -','_').downcase.match(/^[a-zA-Z][a-zA-Z_]+/)
				return obj.tr(' -', '_').downcase.to_sym
		end	
		return obj
	end

    def symbolize
		_symbolize self
    end
end

file='device.yaml'
conf=parse_yaml(file).symbolize

commands={}

conf[:addr].each do |k,v|
	commands[k]=ViessmanCommand.new(k, v)
end

commands.each do |cmd, command|
	puts "#{cmd}:\n"
	pp command.path
end
