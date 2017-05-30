require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

class SequenceQuery
		attr_accessor :query

	def initialize(query)
		@query = query
	end
	def format(input)
		input.gsub(', ', ',').gsub(' ', ',')
	end
	def fetch()
		data = []
		metadata = []
		seq = format(@query)
		if (seq.include? "," || seq.size >= 5)
			page = HTTParty.get("https://oeis.org/search?q=#{URI::encode(seq)}&sort=&language=&go=Search")
			parse_page = Nokogiri::HTML(page)

			a_codes = parse_page.css('table table table tr td:first-child a[href^="/A"]')
			descriptions = parse_page.css('table table tr[bgcolor="#EEEEFF"] table tr td:nth-child(3)')
			sequences = parse_page.css('table table table tr td:nth-child(2) tt')

			a_codes = a_codes.map {|a| a.text}
			descriptions = descriptions.map {|description| description.text.strip.gsub("\n","").gsub("   ", "")}
			sequences = sequences.map {|sequences| sequences.text}

			col_length = 55
			descriptions.each_with_index do |description, i|
				# line = "#{a_codes[i]} #{description}"
				# elipse = line.length > col_length  ? "..." : ""
				metadata.push("#{a_codes[i]} #{description}")

				# line = "#{seq[0..col_length]}"
				# elipse = line.length > col_length  ? "..." : ""
				data.push("#{seq}")
			end
		end
		return data, metadata
	end
end


