class Analytics
	attr_accessor :settings

	def initialize(*args)
		@result_data = []
		@result_metadata = []
		@settings = Hash.new
		set_settings({"foo"=>"bar", "input"=> { 'data'=>[], 'metadata'=>[] }})
	end

	def set_settings(settings)
		unless settings.nil?
			if !settings['key'].nil?
				@settings['key'] = settings['key']
			end
			if !settings['input'].nil?
				@settings['input'] = settings['input']
			end
		end
	end

	def process()

		def add_to_result (data, metadata)
			if (metadata.is_a? Array)
				if !metadata.empty?
					metadata.each_with_index do |metadatum, i|
						if !metadatum.nil?
							@result_data.push(data[i])
							@result_metadata.push(metadatum)
						end
					end
					return true
				end
				return false
			elsif !metadata.nil?
				@result_data.push(data)
				@result_metadata.push(metadata)
				return true
			end
			return false
		end

		def alpha_analytics(alpha)
			AlphaConstants::REGEXES.each do |regex|
				add_to_result(alpha, is_regex_match(alpha, regex))
			end

			add_to_result(alpha, is_palindromic(alpha))

			if alpha.match(/\s/).nil? 
				group_by_1 = alpha.scan(/.{1}/)
				group_by_2 = alpha.scan(/.{2}/)
				group_by_3 = alpha.scan(/.{3}/)

				add_to_result(group_by_1.join(' '), get_alpha_range(group_by_1, 1))
				add_to_result(group_by_2.join(' '), get_alpha_range(group_by_2, 2))
				add_to_result(group_by_3.join(' '), get_alpha_range(group_by_3, 3))
			end

			chart = AsciiCharts::Cartesian.new(get_char_counts(alpha), :bar => true, :hide_zero => true).draw
			add_to_result(alpha, chart);
		end

		def numberic_analytics(num)
			unless num.is_a? String
				num = num.to_s
			end
			if /[0-9]+/.match(num).to_s == num

				add_to_result(num, "Length: #{num.size}")

				one_dig = num.scan(/.{1}/).join(' ')
				two_dig = num.scan(/.{2}/).join(' ')
				three_dig = num.scan(/.{3}/).join(' ')
				[one_dig, two_dig, three_dig].each do |num|
					num_arr = num.split(' ')
					add_to_result(num, get_range(num_arr, num_arr.first.to_s.size))
					add_to_result(num, is_palindromic(num_arr))

					sequence_query = SequenceQuery.new(num)
					add_to_result(*sequence_query.fetch())
				end

				add_to_result(num, is_palindromic(num))

				num.each_char.with_index {|n, i| add_to_result(num, is_date(num[i..i+7]))}
				num.each_char.with_index {|n, i| add_to_result(num, is_date(num[i..i+5]))}

				if num.size >= 4
					NumberConstants::MATH.each do |constant|
						add_to_result(num, is_in_constant(num, constant))
					end
					NumberConstants::CHEMISTRY.each do |constant|
						add_to_result(num, is_in_constant(num, constant))
					end
					NumberConstants::PHYSICS.each do |constant|
						add_to_result(num, is_in_constant(num, constant))
					end
					NumberConstants::REGEXES.each do |regex|
						add_to_result(num, is_regex_match(num, regex))
					end
				end


			elsif (/[0-9\s]+/.match(num).to_s == num) || (/[0-9,]+/.match(num).to_s == num)
				num_arr = /[0-9\s]+/.match(num).to_s == num ? num.split(' ') : num.split(',')
				num_arr.map! { |num| num = num.to_i }

				add_to_result(num, get_range(num_arr))
				add_to_result(num, is_palindromic(num_arr))

				NumberConstants::SEQUENCES.each do |sequence|
					add_to_result(num, is_in_sequence(num_arr, sequence))
				end
				NumberConstants::RANGES.each do |range|
					range.each do |r|
						if add_to_result(num, is_in_range(num_arr, r))
							break
						end
					end
				end
				sequence_query = SequenceQuery.new(num)
				add_to_result(*sequence_query.fetch())
			end
		end
		data = []
		data[0] = @settings['input']["data"].length > 1 ? @settings['input']["data"].join(' ') : @settings['input']["data"][0]
		
		data.each_with_index do |datum|
			if (/[0-9]+/.match(datum).to_s == datum) || (/[0-9\s]+/.match(datum).to_s == datum) || (/[0-9,]+/.match(datum).to_s == datum)
				numberic_analytics(datum)
			else
				alpha_analytics(datum)
			end
		end
		result = Hash.new
		result['data'] = @result_data
		result['metadata'] = @result_metadata 
		return result
	end

	def get_counts(input_arr)
		if input_arr.first.is_a? String
			input_arr.map! {|num| num = num.to_i}
		end
		min = input_arr.min
		max = input_arr.max
		unique = input_arr.uniq.length
		return { "min": min, "max": max, "unique": unique }
	end
	def get_range(input_arr, digits="Dynamic")
		counts = get_counts(input_arr)
		return "#{digits} Digits: Min:#{counts[:min]} Max:#{counts[:max]} Range:#{counts[:max] - counts[:min]} Unique:#{counts[:unique]} " 
	end
	def get_alpha_range(input_arr, grouping)
		lower = ('a'..'z').to_a
		lower2 = ('aa'..'zz').to_a
		lower3 = ('aaa'..'zzz').to_a

		upper = ('A'..'Z').to_a
		upper2 = ('AA'..'ZZ').to_a
		upper3 = ('AAA'..'ZZZ').to_a

		combined = upper + lower
		combined2 = upper2 + lower2
		combined3 = upper3 + lower3

		is_combined = input_arr.reject {|x| 
			x.split('').reject {|y| combined.include? y}.empty?
		}.empty?
		if !is_combined
			return
		end
		is_lower = input_arr.reject {|x| 
			x.split('').reject {|y| lower.include? y}.empty?
		}.empty?
		is_upper = input_arr.reject {|x| 
			x.split('').reject {|y| lower.include? y}.empty?
		}.empty?

		if grouping == 1
			alphabet = is_lower ? lower : is_upper ? upper : combined
		elsif grouping == 2
			alphabet = is_lower ? lower2 : is_upper ? upper2 : combined2
		elsif grouping == 3
			alphabet = is_lower ? lower3 : is_upper ? upper3 : combined3
		end

		num_arr = input_arr.map {|x|
			alphabet.index(x)
		}

		counts = get_counts(num_arr)
		min = counts[:min].to_s
		min = ' ' * (5 - min.length) + min
		max = counts[:max].to_s
		max = ' ' * (5 - max.length) + max

		rng = (counts[:max] - counts[:min]).to_s
		rng = ' ' * (5 - rng.length) + rng
		unq = counts[:unique].to_s
		unq = ' ' * (3 - unq.length) + unq

		size = input_arr.length.to_s
		size = ' ' * (3-size.length) + size
		return "Chunk #{grouping}: Min:#{min} Max:#{max} Rng:#{rng} Uniq:#{unq} Size:#{size}" 
	end
	def is_in_range(input_arr, range)
		counts = get_counts(input_arr)
		if (range[:max] >= counts[:max]) && (range[:min] <= counts[:min])
			return "Range: #{range[:name]}"
		end
	end
	def is_in_constant(input, constant)
		known_number = constant[:number].gsub('.', '')
		index = known_number.index(input)
		unless index.nil?
			return "Exist in: #{constant[:name]}"
		end
	end
	def is_in_sequence(input_arr, sequence)
		diff = input_arr - sequence[:sequence]
		if diff.empty?
			return "Exist in sequence: #{sequence[:name]}"
		end 
	end
	def is_regex_match(input, regex)
		if input.match(regex[:regex]).to_s == input
			return "Regex match: #{regex[:name]}"
		end
	end
	def is_date(input)
		if !input.nil? && (input.size == 8)
			if (input[0..1].to_i > 0 && input[0..1].to_i <= 12) && \
				(input[2..3].to_i > 0 && input[2..3].to_i <= 31) && \
				(input[4..7].to_i > 1900 && input[4..7].to_i <= 2030)
				return "Possible Date: #{input}"
			end
		elsif !input.nil? && (input.size == 6)
			if (input[0..1].to_i > 0 && input[0..1].to_i <= 12) && \
				(input[2..3].to_i > 0 && input[2..3].to_i <= 31) && \
				(input[4..5].to_i > 0 && input[4..5].to_i <= 99 )
				return "Possible Date: #{input}"
			end
		end
	end
	def is_palindromic(input)
		if input.is_a? String
			if input == input.reverse
				return "Palandromic"
			end
		elsif input.is_a? Array 
			min_length = 2
			includes_above_min = false
			input.each do |x|
				if x.to_s.size >= min_length
					includes_above_min = true
					break
				end
			end
			if includes_above_min
				any_not_palandromic = input.any? do |str|
					str.to_s != str.to_s.reverse
				end 
				unless any_not_palandromic
					return "All Palandromic"
				end
			end
		end
	end
	def get_char_counts(input)
		counts = Hash.new(0)
		input.each_char do |a|
			counts[a] += 1
		end
		counts[' '] = 0
		return counts.to_a.sort
	end
end