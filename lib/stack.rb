#!/usr/bin/ruby


class Stack
	def initialize values=[]
		@values = values
	end
	
	def << v
		if v.is_a? Array
			v.each { |e| @values << e}
		else
			@values << v
		end
	end
	
	def each &block
		@values.each block
	end
	
	def get index
		@values[index]
	end
	
	def push v
		self.<< v
	end
	
	def pop
		@values.pop
	end
	
	def shift
		@values.shift
	end
	
	def values
		@values
	end
	
	def to_s
		'[' + @values.join(",") + ']'
	end
	
	def size
		@values.size
	end

	def sum
		@values.reduce(:+)
	end

	def avg
		size==0?0:sum / size
	end

	def max
		size==0 ? 0 : @values.max
	end

	def min
		size==0 ? 0 : @values.min
	end

end

# same stack with a limited size ; will never be biger than size.
# when push over the size, elements are rotating.
class StackSize < Stack

	def initialize size=10
		super []
		@size=size
	end

	def << v
		super v
		shift if size > @size
	end
	
	def to_s
		super + sprintf(" ; min:%s ; max:%s ; avg:%s", min, max, avg)
	end
end

# s=StackSize.new 60
# (0..60).each do |i|
#   s.push 20+rand(10)
# end
