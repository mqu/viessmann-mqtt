#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")
require "main.rb"
require "pp"
require 'mqtt'

# my libraries
require 'stack.rb'
require 'viessman-sock-reader.rb'
require 'heater-calc.rb'
require 'sqlite.rb'

class Mqtt < MQTT::Client

	def initialize opts
		super()
		self.host = opts[:host]
		self.port = opts[:port]
		self.username = opts[:user]
		self.password = opts[:password]
		
		# self.client_id =  opts[:id]
		# self.port=8883 # over SSL
		# self.ssl = false # when true trigger : in `connect': SSL_connect SYSCALL returned=5 errno=0 state=SSLv2/v3 read server hello A (OpenSSL::SSL::SSLError)
	end

	def base= base
		@base=base
	end

	def publish topic, value, retain=true
		# puts "publish() : #{topic} / #{value}"
		super(sprintf("%s/%s", @base,topic).sub('//','/'), value, retain)
	end
end

class Variable
	def initialize delta, timeout, topic, variable, proc=nil, extra=nil
		@cache=0
		@topic=topic
		@variable=variable
		@proc=proc
		@extra=extra
		@timeout=timeout
		@time=Time.now.to_i

		# do not update is change less than delta
		@delta=delta
	end
	
	def check_for_update viessmann, mqtt
	
		update=false

		# puts "check_for_update()"
		v=viessmann.get(@variable).to_f
		v=@proc.call(@extra) unless @proc==nil
		diff=(v-@cache).abs

		update=true if Time.now.to_i-@time>60 && diff!=0

		update=true if @delta==nil || diff>@delta
		
		if update
			t=Time.now.strftime("%H:%M:%S")
			puts "#{t} publishing new value : #{@topic}=#{v.to_s}"
			mqtt.publish @topic, v
			@cache=v
			@time=Time.now.to_i
		end
	end
end

class VariableAvg < Variable

	def initialize count, round, topic, variable
		@count, @round, @topic, @variable=count, round, topic, variable
		@stack = StackSize.new count
		@cache=nil
	end


	def check_for_update viessmann, mqtt
	
		update=false

		v=viessmann.get(@variable).to_f
		@stack.push v
		@cache=@stack.avg.round(@round) if @cache==nil

		# puts "VariableAvg::check() : #{v} ; #{@stack.avg.round(1)} - #{@stack.avg.round(4)}"
		v=@stack.avg.round(@round)
		diff=(v-@cache).abs

		update=true if @stack.size==1
		update=true if diff>0
		
		if update
			t=Time.now.strftime("%H:%M:%S")
			puts "#{t} publishing new value : #{@topic}=#{v.to_s}"
			mqtt.publish @topic, v
			@cache=v
		end
	end
end

calc=ViessmanCalc.new @config[:device][:power][:max]   # power : 19kw

v=ViessmannSockReader.new
db=ViessmannSqlite.new @config[:global][:sqlite][:db]

at_exit do
	# puts "script exiting ... ; time: " + Time.now.strftime("%d/%m/%Y %H:%M\n")
end

mqtt_client = Mqtt.new @config[:mqtt]

mqtt_client.connect() do |mqtt|
   puts "connected"

	# MQTT base topic; mqtt.publish topic will add this based name to topic.
	mqtt.base=sprintf('%s/%s/objects/%s', 
		@config[:mqtt][:version], 
		@config[:mqtt][:location], 
		@config[:mqtt][:device][:name])

	vars={
		:th1=>[],  # will scan every 10 seconds
		:th2=>[],  # will scan every 60 seconds
		:th3=>[]   # will scan every 30 mn
	}

	#every tempurature values

	vars[:th1]<<VariableAvg.new(10, 1, "/data/temp/indoor",          :indoor_temp)
	vars[:th1]<<VariableAvg.new(10, 1,"/data/temp/outdoor",          :outdoor_temp)
	vars[:th1]<<VariableAvg.new(10, 0, "/data/temp/boiler",          :boiler_temp)
	vars[:th1]<<VariableAvg.new(10, 0, "/data/temp/hot-water",       :hot_water_temp)
	vars[:th1]<<VariableAvg.new(10, 0, "/data/temp/gaz",             :boiler_gaz_temp)
	vars[:th1]<<VariableAvg.new( 5, 0, "/data/stats/heater-power",   :power)

	# other values
	vars[:th1]<<Variable.new(   0, 30, "/data/stats/valve/value",   :valve_setting)
	vars[:th1]<<Variable.new(   0, 30, "/data/stats/valve/text",    :valve_setting_text)
	

	# config (settings)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/power/value",   :mode)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/power/text",    :mode_text)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/eco-mode",      :eco_mode)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/party-mode",    :party_mode)

	# config (settings)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/temp/hot-watter",   :hot_water_set)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/temp/room/normal",  :norm_room_temp)
	vars[:th2]<<Variable.new(   0, 10, "/data/settings/temp/room/low",     :red_room_temp)

	# compute kwh
	p1=Proc.new { |_when|
		calc.kwh(db.sum(_when))
	}

	# compute price
	p2=Proc.new { |_when|
		calc.price(db.sum(_when))
	}

	vars[:th2]<<Variable.new(   0,  10, "/data/stats/kwh/today",    nil, p1, :today)
	vars[:th2]<<Variable.new(   0,  10, "/data/stats/price/today",  nil, p2, :today)

	vars[:th3]<<Variable.new(   0,  600, "/data/stats/kwh/yesterday",    nil, p1, :yesterday)
	vars[:th3]<<Variable.new(   0,  600, "/data/stats/price/yesterday",  nil, p2, :yesterday)

	vars[:th3]<<Variable.new(   0,  600, "/data/stats/kwh/this-month",    nil, p1, :this_month)
	vars[:th3]<<Variable.new(   0,  600, "/data/stats/price/this-month",  nil, p2, :this_month)

	vars[:th3]<<Variable.new(   0,  600, "/data/stats/kwh/this-week",    nil, p1, :this_week)
	vars[:th3]<<Variable.new(   0,  600, "/data/stats/price/this-week",  nil, p2, :this_week)

	vars[:th3]<<Variable.new(   0,  600, "/data/stats/kwh/last-week",    nil, p1, :last_week)
	vars[:th3]<<Variable.new(   0,  600, "/data/stats/price/last-week",  nil, p2, :last_week)


	# 	# kw / last hour
	# 	power=v.get(:power).to_s
	# 	calc.push power.to_i
	# 	val=calc.kwh_hour.round(2)
	# 	mqtt.publish(sprintf("%s/data/stats/kwh/hour", base), val.to_s, retain)
	# 
	# 	# kw / last hour
	# 	val=calc.price_hour.round(2).to_s
	# 	mqtt.publish(sprintf("%s/data/stats/price/hour", base), val.to_s, retain)


	th1=Thread.new {
		while true do
			# puts "th1"
			vars[:th1].each do |var|
				var.check_for_update v, mqtt
			end

			sleep 5
			STDOUT.flush
		end
	}

	th2=Thread.new {
		while true do
			# puts "th2"
			vars[:th2].each do |var|
				var.check_for_update v, mqtt
			end

			sleep 15
			STDOUT.flush
		end
	}

	th3=Thread.new {
		while true do
			# puts "th2"
			vars[:th3].each do |var|
				var.check_for_update v, mqtt
			end

			sleep 60*30
			STDOUT.flush
		end
	}


	while true do

		# puts "th1 is runnging"
		sleep 1

	end   
end
