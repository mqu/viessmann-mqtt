
class Timer
	def initialize
		#nop
	end
	
	def sleep interval
		t=Time.now
		s=t.to_i
		mod=s%interval
		ms=t.to_f.divmod(1)[1]
		sleep=interval - ms - mod
		(sleep<-1)?0:sleep
		Kernel::sleep sleep
		self.trace
	end
	
	def trace
		h=Time.now.strftime("%H:%M:%S.%L\n")
		# puts "waiting done ; time is #{h}"
	end
end
