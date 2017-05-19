#!/usr/local/bin/ruby

# require './analytics/analytics'
# require './analytics/analytics_data/alpha_constants'
# require './analytics/analytics_data/number_constants'
# require 'ascii_charts'
require 'net/http'

def watch(message)
	if message.match(/list/i) || message.match(/show/i)
		return format_monospaced_report(File.read($watch_file))
	end
	if message.match(/add/i)
		urls_string = message.match(/((http[s]?):)(.+)/i).to_s.strip
		if urls_string.size == 0
			return "Error parsing url from `add watch` command. Try again. Ex: `@wafflebot add watch http://foo.com/`"
		end
		urls = urls_string.split(' ')
		urls.each do |url|
			encoded_url = URI.encode(url)
			uri = URI.parse(encoded_url)
			res = Net::HTTP.get(uri)
			puts res
		end
		return 'see output'

	end
	if message.match(/del/i) || message.match(/remove/i)

	end
	return "watch commands:\n `list watch` \n `add watch <url>` \n `delete watch <url>`"

end

message = "@wafflebot add watch http://curious.codes/HereComesTheSun/OarFinBatBoatCornBam/Sweathogs/nothingatall/"
puts watch(message)