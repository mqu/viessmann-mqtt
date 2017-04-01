#!/usr/bin/ruby

require 'stack.rb'

class HeaterCalculator

	def initialize power=19

		@power=power  # power in kw

		# https://www.fournisseurs-electricite.com/france/169-infos/18348-prix-kwh-gaz
		@price=0.05310 # price by kwh

		# stacks
		@hour=StackSize.new 60
		@day=StackSize.new 24
		@week=StackSize.new 7
		@month=StackSize.new 31
		
	end
	
	def push percent
		@hour.push percent
	end
	
	def kwh_hour
		kwh_by_mn=1.0*@power/60
		kwh_by_mn * @hour.sum / 100
	end

	def price_hour
		self.kwh_hour * @price
	end
end

