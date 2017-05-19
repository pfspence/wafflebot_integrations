#!/usr/local/bin/ruby

require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'

class DrawConnection
		attr_accessor :query
		attr_accessor :wikipedia_urls

		$pronouns = ["aboard", "about", "above", "across", "after", "against", "along", "although", "amid", "among", "anti", "around", "as", "at", "before", "behind", "below", "beneath", "beside", "besides", "between", "beyond", "but", "by", "concerning", "considering", "despite", "down", "during", "except", "excepting", "excluding", "following", "for", "from", "here", "however", "in", "inside", "into", "like", "many", "minus", "near", "of", "off", "on", "onto", "opposite", "other", "outside", "over", "past", "per", "plus", "regarding", "round", "save", "since", "than", "that", "the", "there", "these", "they", "this", "through", "to", "together", "toward", "towards", "under", "underneath", "unlike", "until", "up", "upon", "versus", "via", "when", "while", "with", "within", "without"]
		$months = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"]
		$proper_nouns = ["wikimedia", "commons"]
		$common_names = ["bob", "james", "john", "robert", "michael", "william", "david", "richard", "charles", "joseph", "thomas", "christopher", "daniel", "paul", "mark", "donald", "george", "kenneth", "steven", "edward", "brian", "ronald", "anthony", "kevin", "jason", "matthew", "gary", "timothy", "jose", "larry", "jeffrey", "frank", "scott", "eric", "stephen", "andrew", "raymond", "gregory", "joshua", "jerry", "dennis", "walter", "patrick", "peter", "harold", "douglas", "henry", "carl", "arthur", "ryan", "roger", "joe", "juan", "jack", "albert", "jonathan", "justin", "terry", "gerald", "keith", "samuel", "willie", "ralph", "lawrence", "nicholas", "roy", "benjamin", "bruce", "brandon", "adam", "harry", "fred", "wayne", "billy", "steve", "louis", "jeremy", "aaron", "randy", "howard", "eugene", "carlos", "russell", "bobby", "victor", "martin", "ernest", "phillip", "todd", "jesse", "craig", "alan", "shawn", "clarence", "sean", "philip", "chris", "johnny", "earl", "jimmy", "antonio", "danny", "bryan", "tony", "luis", "mike", "stanley", "leonard", "nathan", "dale", "manuel", "rodney", "curtis", "norman", "allen", "marvin", "vincent", "glenn", "jeffery", "travis", "jeff", "chad", "jacob", "lee", "melvin", "alfred", "kyle", "francis", "bradley", "jesus", "herbert", "frederick", "ray", "joel", "edwin", "don", "eddie", "ricky", "troy", "randall", "barry", "alexander", "bernard", "mario", "leroy", "francisco", "marcus", "micheal", "theodore", "clifford", "miguel", "oscar", "jay", "jim", "tom", "calvin", "alex", "jon", "ronnie", "bill", "lloyd", "tommy", "leon", "derek"]
	
	def initialize(query)
		@query = query
		@wikipedia_urls = query.split
	end

	def fetch(url)
		def get_page(url)
			page = HTTParty.get(url)
			Nokogiri::HTML(page)
		end

		def get_single_words (text)
			text_arr = text.split(' ')
			text_arr = text_arr.map {|x| x.scan(/[a-zA-Z\d]+/).join('') }
			exclude = $pronouns + $months + $proper_nouns
			text_arr = text_arr.reject {|x| (exclude.include? x.downcase) || x.size < 3 }
			return text_arr
		end
		def get_double_words(text_arr)
			words = text_arr.each_slice(2).map{|a|a.join ' '}
			words += text_arr[1..-1].each_slice(2).map{|a|a.join ' '}
			return words
		end
		def get_triple_words(text_arr)
			words = text_arr.each_slice(3).map{|a|a.join ' '}
			words += text_arr[1..-1].each_slice(3).map{|a|a.join ' '}
			words += text_arr[2..-1].each_slice(3).map{|a|a.join ' '}
			skip_set = []
			words.each do |word|
				word_set = word.split
				word_set[1] = "*"
				skip_set.push(word_set.join(' '))
			end
			return words + skip_set
		end
		def get_cap_words(text_arr)
			cap_words = []
			text_arr.each do |text|
				if (text.downcase != text)
					cap_words.push(text)
				end
			end
			return cap_words
		end

		page = get_page("https://en.wikipedia.org/wiki/#{url}")

		text = page.css('p').text
		text += page.css('table').text
		word_arr = get_single_words(text)
		word_combos = [] + word_arr
		word_combos += get_double_words(word_arr)
		word_combos += get_triple_words(word_arr)
		cap_words = get_cap_words(word_combos)
		return cap_words.reject {|x| $common_names.include? x.downcase}
		# Pry.start(binding)
		
	end
	def get_intersection(){
		sequences = []
		@wikipedia_urls.each do |url|
			sequences.push(fetch(url))
		end

		seq1 = sequences.first
		sequences[1..-1].each do |seq|
			seq1 = seq1 & seq
		end
		return seq1.sort_by {|x| x.length}.reverse
	}
end

# draw_connection = DrawConnection.new("Bruce_Lee The_Muppets Reading_Rainbow")
# puts draw_connection.fetch

