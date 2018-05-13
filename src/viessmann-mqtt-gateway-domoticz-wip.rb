#!/usr/bin/ruby

# Marc Quinton / may 2018 / version 0.1
# this is a WIP (Work in progress) script 
# 
# gateway interface between Domoticz and MQTT
# currently supported :
#  - in : indoor and outdoor temp
#
# todo : on/off heater, indoor setting, ...
#

$LOAD_PATH.unshift("#{File.dirname(File.expand_path(__FILE__))}/..")

require "main.rb"

require "pp"
require 'mqtt'
require 'json'

# my libraries
require 'viessman-sock-reader.rb'
require 'timer.rb'

v=ViessmannSockReader.new
timer=Timer.new

client = MQTT::Client.new
client.host = @config[:mqtt][:host]
client.port = @config[:mqtt][:port]
client.username = @config[:mqtt][:user]
client.password = @config[:mqtt][:password]

# test : 
# - read all MQTT messages from server :
# - MQTT server config : /etc/mosquitto/mosquitto.conf (and password)
#  mosquitto_sub -u user -P your-passwd  -h localhost -v -t "#"
#
# - send a domoticz message.
# mosquitto_pub -u user -P your-passwd -h localhost -t "domoticz/in" -m '{ "idx" : 1, "nvalue" : 32}'

# connect to MQTT server and subscribe to some topics
client.connect() do |mqtt|
   puts "connected to MQTT server"
 
   # messages from Domoticz
   mqtt.subscribe('domoticz/in')   # messages from Viessman to Domoticz
   mqtt.subscribe('domoticz/out')  # messages from Domoticz
   
   # messages from viessman MQTT gateway
   mqtt.subscribe('v1/objects/viessman//data/temp/indoor')
   mqtt.subscribe('v1/objects/viessman//data/temp/outdoor')

   while true  do

	mqtt.get do |topic,message|
		puts "topic=#{topic}=#{message}"
		
		case topic
		
			# viessman -> domoticz / indoor temp
			# please adjust idx values according to your Domoticz settings
			when "v1/objects/viessman//data/temp/indoor"
				puts "indoor"
				values={
					:idx => 1234,    # get index from DomoticZ
					:nvalue => v.get(:indoor_temp)
				}
				mqtt.publish('domoticz/out', values.to_json)
			when "v1/objects/viessman//data/temp/outdoor"
				puts "outdoor"
				values={
					:idx => 1235,    # get index from DomoticZ
					:nvalue => v.get(:outdoor_temp)
				}
				mqtt.publish('domoticz/out', values.to_json)
		end
	end

	STDOUT.flush

	timer.sleep 5
   end
   
end
