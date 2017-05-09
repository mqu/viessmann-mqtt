#!/usr/bin/ruby

libdir="../../lib"
$LOAD_PATH.unshift libdir


# read device.yaml
require 'pp'
require 'yaml'

require 'viessman-raw-read.rb'

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

	def enums default=[]
		return @opts[:enums] if @opts.key? :enums
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

	def raw_read viessmann
		if self.type==:enum
			return self.enums[viessmann.raw_read self.addr, self.type]
		else
			return viessmann.raw_read self.addr, self.type, self.mult
		end
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

class Viessman

	def initialize file

		# handler to vitalk raw read and get
		@v=ViessmannRawTcpClient.new
		
		# 
		@conf=parse_yaml(file).symbolize

		@commands={}

		@conf[:addr].each do |k,v|
			@commands[k]=ViessmanCommand.new(k, v)
		end
	end
	def method_missing(sym, *args)
		return @commands[sym].raw_read(@v) if @commands.key? sym
		throw "error : unkown command(method) (#{sym})"
	end

	def parse_yaml file
		begin
			return YAML.load(File.open(file))
		rescue ArgumentError => e
		  puts "Could not parse YAML file (#{file}: #{e.message}"
		  exit 0
		end
	end

	def get key
		throw "error" unless @commands.key? key
		return @commands[key].raw_read(@v)
	end

	def cmd key
		throw "error" unless @commands.key? key
		return @commands[key]
	end

	def methods
		@commands.keys
	end
end

v=Viessman.new 'device-20CB.yaml'
pp v.device_id
pp v.power
pp v.mode
pp v.indoor_temp

pp v.get(:indoor_temp)
v.methods.each do |cmd|
  puts "#{sprintf("0x%04X", v.cmd(cmd).addr)} : #{cmd} : #{v.get cmd}"
end
