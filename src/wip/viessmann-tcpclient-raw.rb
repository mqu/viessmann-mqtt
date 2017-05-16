#!/usr/bin/ruby

# viessmann raw read and write test with vitalk daemon.
# FIXME, FIXME ... WIP.

#
# ViessmannRawTcpClient::raw_read supported formats
# - :byte    - 1 byte  (mode, party_mode, eco_mode, ...)
# - :short   - 2 bytes (boiler_temp, ...)
# - :int4    - 4 bytes (starts)
# - :addr    - 2 bytes (device-id)
# - :systime - 8 bytes (system time)

libdir="../../lib"
$LOAD_PATH.unshift libdir

require "pp"

# my libraries
require 'viessman-raw-read.rb'

v=ViessmannRawTcpClient.new

puts "device_id=#{v.raw_read 0x00F8, :addr}"

puts "outdoor_temp=#{v.raw_read 0x0800, :short, 10}"
puts "indoor_temp=#{v.raw_read 0x0896, :short, 10}"

puts "boiler_temp=#{v.raw_read 0x0802, :short, 10}"
puts "norm_room_temp=#{v.raw_read 0x2306, :byte, 1}"
puts "reduce_room_temp=#{v.raw_read 0x2307, :byte, 1}"
puts "starts=#{v.raw_read 0x088a, :int4, nil}"
puts "runtime=#{v.raw_read 0x08A7, :int4, nil}"
puts "power=#{v.raw_read 0xa38f, :short, 2}"

puts "mode=#{v.raw_read 0x2323, :byte}"
puts "party_mode=#{v.raw_read 0x2330, :byte}"
puts "eco_mode=#{v.raw_read 0x2331, :byte}"

puts "system_time=#{ v.raw_read 0x088E, :systime}"
puts "system_time=#{ v.raw_read 0x088E, :raw8}"


# puts "hollyday_start=#{}"
# pp v.raw_read 0x2309, :raw8
# 
# puts "hollyday_end=#{}"
# pp v.raw_read 0x2311, :raw8

exit 0


#@commands = {
	#:deviceid            => Command.new(0x00F8, 2, nil, '',  :ro, :addr, 'deviceid',      'Device ID'),

	#:outdoor_temp        => Command.new(0x0800, 2, 10, '°C', :ro, :short, 'outdoor_temp',        'Outdoor temperature'),
	#:indoor_temp         => Command.new(0x0896, 2, 10, '°C', :ro, :short, 'indoor_temp',         'Indoor temperature'),
	#:outdoor_temp_lp     => Command.new(0x5525, 2, 10, '°C', :ro, :short, 'outdoor_temp_lp',     'Outdoor temperature low-pass'),
	#:outdoor_temp_smooth => Command.new(0x5527, 2, 10, '°C', :ro, :short, 'outdoor_temp_smooth', 'Outdoor temperature smooth (attenuated)'),

	#:norm_room_temp      => Command.new(0x2306, 1, nil, '°C', :rw, :byte, 'norm_room_temp',     'Normal room temperature'),
	#:reduce_room_temp    => Command.new(0x2307, 1, nil, '°C', :rw, :byte, 'reduce_room_temp',   'Reduce room temperature'),

	#:boiler_temp         => Command.new(0x0802, 2, 10, '°C', :ro, :short, 'boiler_temp',           'Boiler temperature'),
	#:boiler_temp_lp      => Command.new(0x0810, 2, 10, '°C', :ro, :short, 'boiler_temp_lp',        'Boiler temperature low-pass'),
	#:boiler_temp_set     => Command.new(0x555a, 2, 10, '°C', :ro, :short, 'boiler_temp_set',       'Boiler temperature setpoint'),

	#:hot_water_temp     => Command.new(0x0804, 2, 10, '°C',  :ro, :short, 'hot_water_temp',      'Hot water temperature'),
	#:hot_water_temp_lp  => Command.new(0x0812, 2, 10, '°C',  :ro, :short, 'hot_water_temp_lp',   'Hot water temperature low-pass'),
	#:hot_water_temp_set => Command.new(0x2544, 2, 10, '°C',  :rw, :short, 'hot_water_temp_set',  'Hot water temperature target'),
	#:flow_temp          => Command.new(0x080C, 2, 10, '°C',  :ro, :short, 'flow_temp',           'Flow temperature'),
	#:return_temp        => Command.new(0x080A, 2, 10, '°C',  :ro, :short, 'return_temp',         'Return temperature'),

	## circuit
	#:circuit_flow_temp   => Command.new(0x2544, 2,  10, '°C', :ro, :short, 'circuit_flow_temp',  'Circuit flow temperature'),
	#:curve_level         => Command.new(0x27d4, 1, nil,  'K', :ro, :byte,  'curve_level',        'heating curve level'),
	#:curve_slope         => Command.new(0x27d3, 1,  10,  '',  :ro, :byte,  'curve_slope',        'heating curve slope'),

	## :storage_charge_pump => Command.new(0x0845, 1,  nil,  '',  :ro, :byte, 'storage_charge_pump',  'storage charge pump'),
	## :circulation_pump    => Command.new(0x0846, 1,  nil,  '',  :ro, :byte, 'circulation_pump',     'circulation pump'),
	## :mixer_position      => Command.new(0x254C, 1,    2,  '%', :ro, :byte, 'mixer_position',      'mixer position'),

	#:mode                => Command.new(0x2323, 1, nil, '',   :rw, :enum, 'mode',           'Operating mode', @enums[:mode]),
	#:eco_mode			 => Command.new(0x2302, 1, nil, '',   :rw, :bool, 'eco_mode',       'Eco mode (bool)'),
	#:party_mode			 => Command.new(0x2303, 1, nil, '',   :rw, :bool, 'party_mode',     'Party mode (bool)'),

	#:switching_valve     => Command.new(0x0a10, 1, nil, '',   :ro, :enum, 'switching_valve','switching valve', @enums[:switching_valve]), 
	#:starts              => Command.new(0x088a, 4, nil,  '',  :ro, :int4, 'starts',         'burner starts number'),
	#:runtime             => Command.new(0x08A7, 4, nil,  's', :ro, :int4,  'runtime',        'burner runtime (s)'),
	#:runtime_h           => Command.new(0x08A7, 4, 3600, 'h', :ro, :float, 'runtime_h',      'burner runtime (h)'),
	#:power_pump          => Command.new(0x0a3c, 1, 1,   '%',  :ro, :byte, 'power_pump',      'power pump in %'),
	#:power               => Command.new(0xa38f, 1, 2,   '%',  :ro, :byte, 'power',          'burner power in %'),
	#:flow                => Command.new(0x0c24, 2, 1,   'l/h',:ro, :byte, 'flow',           'flow in l/h'),
	#:exhaust_gaz_temp    => Command.new(0x0808, 2, 10,  '°C', :ro, :short,'exhaust_gaz_temp', 'exhauts gaz temp in °C'),
	#:boiler_output       => Command.new(0xa305, 1, 2,   '%',  :ro, :byte, 'boiler_output',  'boiler output in %'),  # not working ... should see hot water flow ?
	#:frost_danger        => Command.new(0x2510, 1, nil, '',   :ro, :bool, 'frost_danger',   'frost danger'),

	#:system_time         => Command.new(0x088E, 8, nil, '',   :ro, :systime, 'system_time',    'System Time'),
	## :error0              => Command.new(0x7507, 9, nil, '',   :ro, :error,    'error0',    'error 0'),  # errors : 0:, 1:7510, 2:7519, 3:7522, 4:752B, 5:7534, 6:753D, 7:7546, 8:754F, 9:7558
	## :error1              => Command.new(0x7510, 9, nil, '',   :ro, :error,    'error1',    'error 1'),  # errors : 0:, 1:7510, 2:7519, 3:7522, 4:752B, 5:7534, 6:753D, 7:7546, 8:754F, 9:7558
	## :conso               => Command.new(0x7574, 4, nil, '',   :ro, :long,    'conso',    'consomption'),
	## todo : 27e6, 27e7,  : 

#}

# other addresses :
# - https://www.bricozone.fr/t/interface-vitodens-200-avec-raspberry-pi.14671/page-9
# - hollyday start-stop
# 
#     2309, 8 bytes, pour le départ vacances (YMDxhms)
#     2311, 8 bytes, pour fin vacances (YMDxhms)
# 
# Fonctionne en lecture et écriture.
# En lecture faire une conversion base 10 vers hexa
# En écriture faire une conversion hexa vers base 10
# 
# holiday/start
# $rg 0x2309 8
# 25;112;1;1;4;0;0;0;
# holiday/end
# $rg 0x2311 8
# 25;112;1;1;4;0;0;0;


# Je ne pense pas que je câblerai la fonction sous Vitalk ou en PHP, car j'utilise de moins en moins l'application web.
# 
# Pour changer la date et l'heure sur la chaudière, on peut le faire assez facilement. Un simple script en python appelé par crontab permet de synchroniser l'heure, adresse 088E, 8 bytes (YMDxhms)
# En lecture faire une conversion base 10 vers hexa
# En écriture faire une conversion hexa vers base 10
# 
# x est le jour de la semaine 1 lundi et 7 dimanche.
# 
# Pour ceux qui paramètrent codage 1 ou 2 à partir de l'application, pour la puissance bruleur vous avez l'adresse mémoire 8832, sur 1 bytes (0 à 100).

# plages d'adresses pour plages horaires :
# 2000/8 ... 2230/8
# php-script : http://easydomoticz.com/forum/viewtopic.php?f=17&t=1955&start=220
# https://homematic-forum.de/forum/viewtopic.php?f=48&t=21640&start=30
