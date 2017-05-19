require 'net/http'
require 'uri'
require 'Pry'

class UrlListManager


	def initialize()

	end
	$watch_file = "./watch_file.txt"

	def get_unique_urls(urls)
		urls = (urls.is_a? Array) ? urls : [urls]
		report = ''
		file_urls = File.readlines($watch_file)
		unique_urls = urls - file_urls.map {|x| x.strip}
		duplicates = file_urls.map {|x| x.strip} & urls
		# Pry.start(binding)
		if !duplicates.empty?
			duplicates.each do |url|
				report += "-- Already in watch file: #{url} "
			end
		end
		return unique_urls, report
	end
	def add_uris(uris)
		open($watch_file, 'a') { |f|
			uris.each do |uri|
				f.puts uri.to_s
			end
		}
	end
	def delete(urls)
		report = ''
		file_urls = File.readlines($watch_file)
		file_urls.map! { |url| url.strip }
		keep = file_urls - urls
		removed = urls.each { |url| file_urls.include? url}

		File.open($watch_file, "w+") do |f|
			keep.each { |url| f.puts(url) }
		end
		if !removed.nil?
			removed.each do |url|
				report += "Removed from watch file: #{url} "
			end
		end
		return report
	end
	def read() 
		File.read($watch_file)
	end
	def add(urls)
		urls, report = get_unique_urls(urls)
		uris = urls.map {|url|
			encoded_url = URI.encode(url)
			URI.parse(encoded_url)	
		}

		uris.each do |uri|
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Get.new(uri.request_uri)
			response = http.request(request)
			report += "Response: #{response.code} Added watch on #{uri}\n" 
		end
		add_uris(uris) 
		return report
	end
	def get_urls(message)
			urls_string = message.match(/((http[s]?):)(.+)/i).to_s.strip.gsub('<', '').gsub('>', '')
			return urls_string.size == 0 ? [] : urls_string.split(' ')
	end
	def nuke_watch_file()
		lines = []
		File.open($watch_file, "w+") do |f|
			lines.each { |line| f.puts(line) }
		end
	end
end