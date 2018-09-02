#!/usr/bin/ruby

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")

require "main.rb"
require "pp"
require 'mqtt'

at_exit do
	puts "script exiting ... ; time: " + Time.now.strftime("%d/%m/%Y %H:%M\n")
end
# Cayenne MQTT API - http://mydevices.com/cayenne/docs/
# data types : http://mydevices.com/cayenne/docs/#bring-your-own-thing-api-supported-data-types
# units : 
#  - percent: p
#  - digital (0,1) : d
#  - power (pow) / w    (watt)
#  - temp / f,c,k  
#  - time / sec, msec, min, hour, day, month, year
#  - weight / kg, lbs

class CayenneMqtt

	def initialize opts
		@opts=opts

		@mqtt=MQTT::Client.new
		@mqtt.host = opts[:server]
		@mqtt.username = opts[:user]
		@mqtt.password = opts[:passwd]
		@mqtt.client_id =  opts[:id]

		@mqtt.port = 1883
		@mqtt.ssl = false # when true trigger : in `connect': SSL_connect SYSCALL returned=5 errno=0 state=SSLv2/v3 read server hello A (OpenSSL::SSL::SSLError)
		@mqtt.version = '3.1.1'  # avoid exception :  "Client identifier too long when serialising packet"

		self.connect
		self.send_sysinfo
	end

	def base
	   base=sprintf('v1/%s/things/%s', @opts[:user], @opts[:id])
	end

	def connect 
		@mqtt.connect
	end

	def publish topic, value
		_topic=sprintf("%s/%s", self.base, topic).sub('//','/')
		# puts "CayenneMqtt::publish(#{_topic}:#{value}"
		@mqtt.publish(_topic, value)
	end

	# sensor data :
	# v1/username/things/clientID/data/channel - type,unit=val
	# ex : PUB v1/A1234B5678C/things/0123-4567-89AB-CDEF/data/2  - temp,c=20.7
	#          v1/b4f34b50-e4/things/07115e70-e4d3-11e6-/data/1
	def publish_channel channel, type, value
		# c.publish(sprintf("%s/data/%s", self.base, channel), value)

		topic=sprintf("/data/%s", channel.to_s)

		case type
			when :temp
				value=sprintf('temp,c=%s',value.to_s)
			when :power
				value=sprintf('power,p=%s',value.to_s)
			when :kwh
				value=sprintf('power,kwh=%s',value.to_s)
			when :percent
				value=sprintf('percent,d=%s',value.to_s)
			when :switch
				value=sprintf('switch,d=%s',value.to_s)
			else
				value=sprintf('value,d=%s',value.to_s)
		end
		
		self.publish(topic, value)
	end

	def send_sysinfo
		   # system info
			puts "CayenneMqtt::init() : sending sysinfo"
		   self.publish '/sys/model'  ,'cayenne-mqtt-ruby-client'
		   self.publish '/sys/version', '0.1'
	end
end


cayenne_mqtt_opts = {
	:server => @config[:cayenne][:host],
	:user   => @config[:cayenne][:user],
	:passwd => @config[:cayenne][:password],
	:id     => @config[:cayenne][:id]       # object / client id
}

begin
	cayenne=CayenneMqtt.new cayenne_mqtt_opts
rescue => e
	puts "caught exception"
	sleep 5
	retry
	pp e
end

client = MQTT::Client.new
client.host = @config[:mqtt][:host]
client.port = @config[:mqtt][:port]
client.username = @config[:mqtt][:user]
client.password = @config[:mqtt][:password]

# options for MQTT subject
opts={
	:location => @config[:mqtt][:location],
	:device => {
		:name => @config[:mqtt][:device][:name],
		:type => @config[:mqtt][:device][:type]
	}
}

def main mqtt, cayenne, opts

   base=sprintf('v1/%s/objects/%s', opts[:location], opts[:device][:name])
   puts "base=#{base}\n"

   topics=[]
   topics << sprintf("%s/data/#", base)

   puts "subscribing topics="
   pp topics

   mqtt.subscribe(topics)

   while true  do

	mqtt.get do |topic,message|
		topic=topic.sub(base,'')
		# puts "topic=#{topic}:#{message}"

		# data/settings/power/mode
		# data/settings/power/text
		# data/settings/power/value
		# data/settings/temp/hot-watter

		# data/stats/price/hour
		# data/stats/price/last-week
		# data/stats/price/this-month
		# data/stats/price/this-week
		# data/stats/price/today
		# data/stats/price/yesterday
		# data/stats/pump-power
		# data/stats/runtime-h
		# data/stats/starts
		# data/stats/valve/text
		# data/stats/valve/value
		# data/temp/boiler
		# data/temp/gaz
		# data/temp/hot-water

		case topic

			when '/data/temp/indoor'
				cayenne.publish_channel(1, :temp, message.to_s)

			when '/data/temp/outdoor'
				cayenne.publish_channel(2, :temp, message.to_s)
		
			when '/data/stats/heater-power'
				cayenne.publish_channel(3, :percent, message.to_s)

			when '/data/stats/pump-power'
				cayenne.publish_channel(4, :percent, message.to_s)

			when '/data/temp/boiler'
				cayenne.publish_channel(5, :temp, message.to_s)
	
			when '/data/temp/gaz'
				cayenne.publish_channel(6, :temp, message.to_s)
	
			when '/data/temp/hot-water'
				cayenne.publish_channel(7, :temp, message.to_s)

			when '/data/settings/power/mode'
				cayenne.publish_channel(8, :switch, message.to_s)
			when '/data/settings/eco-mode'
				cayenne.publish_channel(9, :switch, message.to_s)
			when '/data/settings/party-mode'
				cayenne.publish_channel(10, :switch, message.to_s)

			when 'data/settings/temp/room/normal'
				cayenne.publish_channel(11, :temp, message.to_s)
			when 'data/settings/temp/room/low'
				cayenne.publish_channel(12, :temp, message.to_s)

			when '/data/stats/kwh/today'
				cayenne.publish_channel(13, :power, message.to_s)
			when '/data/stats/kwh/yesterday'
				cayenne.publish_channel(14, :power, message.to_s)
			when '/data/stats/kwh/this-week'
				cayenne.publish_channel(15, :power, message.to_s)
			when '/data/stats/kwh/this-month'
				cayenne.publish_channel(16, :power, message.to_s)

			else
				# puts "topic unknown or unmanaged ... #{topic} : #{message.to_s}"
		end
	end

	STDOUT.flush

	timer.sleep 60
   end
   
end

while true do
	begin
		client.connect() do |mqtt|
			puts "connected to MQTT server"
			main mqtt, cayenne, opts
		end 
	rescue MQTT::ProtocolException, Errno::ECONNREFUSED  => e # may receive MQTT::ProtocolException ; Errno::ECONNREFUSED

		client = MQTT::Client.new
		client.host = @config[:mqtt][:host]
		client.port = @config[:mqtt][:port]
		client.username = @config[:mqtt][:user]
		client.password = @config[:mqtt][:password]

		puts "exception from MQTT ; sleeping and going to retry ..."
		puts e.to_s
		pp e
		sleep 5
		# retry to connect and process
		retry
	end
	
	# we may never get here.
	puts "disconnected from MQTT ; sleeping and going to retry"
	sleep 5
end


exit 0

client.connect() do |mqtt|
	puts "connected"
	main mqtt, cayenne, opts
end
