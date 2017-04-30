#!/usr/bin/ruby

require 'socket'

# this class ViessmannSockReader is used to get and set values to Viessmann heater
# using vitalk application : 
#  - original vitalk application was writen by klauweg - https://github.com/klauweg/vitalk
#  - this application has been translated in english, for external commands, by mqu : https://github.com/mqu/vitalk
#  - depending on your device, you may need to adapt this application (vitalk) to get and set values. 
#    (https://openv.wikispaces.com/Adressen)
# 
# links about Vitalk : 
# - https://openv.wikispaces.com/ViTalk
# - https://openv.wikispaces.com/
# 
# about vitalk
# - starting application : vitalk -t /dev/ttyUSB0 &
# - application opens a TCP server where you can run commands
# - default port is 3083
# - you can run multiple connexion to vitalk server (multi-threaded) limited to 20 (telnet.h:MAX_DESCRIPTOR)
# - below, you can see some interactions with vitalk.
# - some vitalk version have an extended command (raw mode) allowing to read any adress : rg <addr> <num-bytes>
#   - this command may not be in the help menu.

# Short Help Text:
#   h, help                 - This Help Text
#   frame_debug <on/off>    - Set state of Frame Debugging
#   list [class]            - Show parameter List
#   g, get <p_name>         - Query Parameter
#   gvu <p_name>            - Get Value of Parameter with Unit
#   s, set <p_name> <value> - Set Parameter
#   gc <class>              - Query a class of Parameters
#      Parameterklassen:
#        P_ALLE       0
#        P_ERRORS     1
#        P_ALLGEMEIN  2
#        P_KESSEL     3
#        P_WARMWASSER 4
#        P_HEIZKREIS  5
#        P_BRENNER    6
#        P_HYDRAULIK  7
# 
# list
# 01:               errors: Error History (numerisch)
# 01:          errors_text: Error History (text)
# 02:             deviceid: Device ID
# 02:          system_time: System time
# 02:                 mode: operating mode (numerisch)
# 02:            mode_text: operating mode (text)
# 02:          indoor_temp: Indoor temperature
# 02:         outdoor_temp: Outdoor temperature
# 02:      outdoor_temp_lp: Outdoor temp / low_pass
# 02:  outdoor_temp_smooth: Outdoor temp / smooth
# 03:          boiler_temp: Boiler temperature
# 03:       boiler_temp_lp: Boiler temp _ low pass
# 03:      set_boiler_temp: Boiler setpoint temperature
# 03:      boiler_gaz_temp: Boiler flue gas temperature
# 04:        hot_water_set: Hot water setting
# 04:       hot_water_temp: Hot water temperature
# 04:    hot_water_temp_lp: Hot water temperature low_pass
# 04:         boiler_offet: boiler Offset
# 05:        flow_temp_set: flow temp setting
# 05:       norm_room_temp: room temp setting
# 05:        red_room_temp: reduced room temp setting
# 05:          curve_level: Curve level
# 05:          curve_slope: Curve  slope
# 05:               pp_max: Maximal pomp power
# 05:               pp_min: Minimal pomp power
# 06:               starts: Heater Starts
# 06:            runtime_h: Runtime in hours
# 06:              runtime: Runtime in seconds
# 06:                power: Power in %
# 07:        valve_setting: valve setting
# 07:   valve_setting_text: valve setting / text
# 07:           pump_power: Pump power

# socket sample output:
#
# marc@rasp:~ $ echo  'gc' | nc localhost 3083
# Welcome at vitalk, the Vitodens telnet Interface. (5)
# 02:             deviceid: 0x20cb 
# 02:          system_time: 2017020305221951 
# 02:                 mode: 2 
# 02:            mode_text: Heating and hot water 
# 02:          indoor_temp: 19.50 °C
# 02:         outdoor_temp: 7.70 °C
# 02:      outdoor_temp_lp: 7.70 °C
# 02:  outdoor_temp_smooth: 8.50 °C
# 03:          boiler_temp: 46.00 °C
# 03:       boiler_temp_lp: 46.00 °C
# 03:      set_boiler_temp: 5.00 °C
# 03:      boiler_gaz_temp: 48.30 °C
# 04:        hot_water_set: 50 °C
# 04:       hot_water_temp: 40.60 °C
# 04:    hot_water_temp_lp: 40.60 °C
# 04:         boiler_offet: 20 K
# 05:        flow_temp_set: 0.00 °C
# 05:       norm_room_temp: 20 °C
# 05:        red_room_temp: 13 °C
# 05:          curve_level: 0 K
# 05:          curve_slope: 1.2 
# 05:               pp_max: 65 %
# 05:               pp_min: 30 %
# 06:               starts: 5288 
# 06:            runtime_h: 3771.6 h
# 06:              runtime: 13577903 s
# 06:                power: 0.0 %
# 07:        valve_setting: 3 
# 07:   valve_setting_text: hot water 
# 07:           pump_power: 0 %

# TODO : use raw-read and raw-write commands (see extra/viessmann/tcp-client-raw.rb)
#  - with raw commands, will be able to support anydevice (only need to write commands in ruby language).
#

# read from vitalk server / deviceid: 0x20cb
class ViessmannSockReader

	def initialize host='localhost', port=3083
		@host=host
		@port=port
		
		begin
			@sock=TCPSocket.new host, port
			@line=@sock.gets  # junk data "Welcome at vitalk, the Vitodens telnet Interface. (5)\n"
		rescue StandardError => e
			throw "can't connect to vitalk server (tcp://#{host}:#{port}) ; you may need to start server"
		end
		@mutex = Mutex.new
	end

	def unpack_addr
		d=self.data
		return Addr::unsplit d[0].ord, d[1].ord
	end

	def puts str
		@mutex.synchronize {
			@sock.puts str.to_s
		}
	end

	def gets
		@mutex.synchronize {
			@sock.gets.chomp
		}
	end
	
	def get var
		@mutex.synchronize {
			@sock.puts "g " + var.to_s
			@sock.gets.chomp
		}
	end
	
	def set var, value
		@mutex.synchronize {
			@sock.puts sprintf("s %s %s", var.to_s, value.to_s)
			@sock.gets.chomp
		}
	end
	
end
