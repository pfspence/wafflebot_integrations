#!/usr/local/bin/ruby
require 'slack-ruby-client'
require 'ascii_charts'
require 'net/http'
require 'uri'
require 'twitter'

require './analytics/analytics'
require './analytics/sequence_query'
require './analytics/analytics_data/alpha_constants'
require './analytics/analytics_data/number_constants'
require './drawconnection/draw_connection'
require './urllistmanager/url_list_manager'
require './tweet_fetcher'


Slack.configure do |config|
	# config.token = ENV['SLACK_BOT_AUTONOMY_TOKEN']
	config.token = ENV['SLACK_TEAM_AWESOME_TOKEN']
end
$client = Slack::RealTime::Client.new
$client.on :hello do
	puts 'Successfully connected.'
end
$channel = ''

$api_map = [
	{'regex': /ron swanson/i, 'url': 'http://ron-swanson-quotes.herokuapp.com/v2/quotes', 'success': Proc.new {|x| '_"' + eval(x).first + '"_' }},
	{'regex': /foaas/i, 'url': 'http://foaas.com/bday/Susan/Tom', 'accept': 'application/json', 'success': Proc.new {|x| '_"' + eval(x)[:message] + '"_'}}
]

MAX_COL_WIDTH = 70

def format_monospaced_report(report)
	report = report.empty? ? ' ' : report
	text = "```#{report}```" 
end

def print_as_file(data, file_name, title, initial_comment)
	File.open(file_name, "w+") do |f|
	  data.each { |result| f.puts(result) }
	end
	$client.web_client.files_upload(
		channels: $channel,
		as_user: true,
		file: Faraday::UploadIO.new(file_name, 'text/plain'),
		title: title,
		filename: file_name,
		initial_comment: initial_comment
	)
end

#TODO: Break this out more.
def get_analytics(message)
	input = !message.index('analytics').nil? ?  message.split('analytics ')[1..-1].join(' ').strip : message.split('analyze ')[1..-1].join(' ').strip

	analytics = Analytics.new
	analytics.set_settings({"input"=> { 'data'=>[input], 'metadata'=>[] }})
	results = analytics.process()

	greatest_width = 0
	results['metadata'].each do |metadatum|
		greatest_width = metadatum.size > greatest_width ? metadatum.size : greatest_width
	end
	col_width = (greatest_width + 10) < MAX_COL_WIDTH ? greatest_width + 10 : MAX_COL_WIDTH

	report = ''
	results['metadata'].each_with_index do |metadatum, i|
		spaces_num = col_width - metadatum.size
		spaces_num = spaces_num > 0 ? spaces_num : 1
		displayed_res = results['data'][i][0..MAX_COL_WIDTH];
		displayed_res = results['data'][i].length > MAX_COL_WIDTH ? displayed_res + '...' : displayed_res
		report += "#{metadatum[0..MAX_COL_WIDTH]}" + " " * spaces_num + "#{displayed_res}\n"
	end
	return format_monospaced_report(report)
end

def get_intersection(message)
	input = !message.index('intersection').nil? ?  message.split('intersection ')[1..-1].join(' ').strip : message.split('connection ')[1..-1].join(' ').strip
	connection = DrawConnection.new(input)
	data = connection.get_intersection()
	file_name = "./intersecting_words.txt"
	title = "Intersecting words on Wikipedia pages #{input}"
	print_as_file(data, file_name, title, '')
end

def get_tweets(message)
	message = message.gsub('<@U3EPYT17G>', '').gsub('<@U3CUMAPE2>', '')
	user_name = message.match(/@\w+/).to_s
	count = message.match(/\d+/).to_s.to_i
	if count == 0
		return "How many tweets do you want? ex `@wafflebot get tweets #{user_name} 42`"
	end
	tweet_fetcher = TweetFetcher.new(user_name, count)
	data = tweet_fetcher.fetch()
	file_name = "./tweets.txt"
	title = "All those tweets from #{user_name} you wanted ..."
	print_as_file(data, file_name, title, '')
end

def manage_url_list(message)
	manager = UrlListManager.new

	if !message.match(/nuke watch/i).nil?
		return manager.nuke_watch_file
	elsif !message.match(/list/i).nil? || !message.match(/show/i).nil?
		return format_monospaced_report( manager.read() )
	elsif !message.match(/add watch/i).nil?
		urls = manager.get_urls(message)
		if urls.length == 0
			return "Error parsing url from `add watch` command. Try again. Ex: `@wafflebot add watch http://foo.com/` or `@wafflebot add watch http://foo.com http://bar.com`"
		end
		return format_monospaced_report( manager.add(urls) )
	elsif !message.match(/del/i).nil? || !message.match(/remove/i).nil?
		urls = manager.get_urls(message)
		if urls.length == 0
			return "Error parsing url from `delete watch` command. Try again. Ex: `@wafflebot delete watch http://foo.com/` or `@wafflebot delete watch http://foo.com http://bar.com`"
		end
		return format_monospaced_report( manager.delete(urls) )
	else
		return "*watch commands:*\n list watch \n add watch <url> \n delete watch <url> \n nuke watch file"
	end
end

def list_commands
	commands = ["`analytics <text>` Performs some pattern matching and character counts.", "`watch <url>` Add url to watch file.", "`get twitter <username> <number of tweets>` Dump twitter feed.", "_All other messages are responded to in chatbot mode_ :robot_face:"]
	return commands.join("\n")
end

def api_call(message)
	$api_map.each do |api|
		if message.match(api[:regex])
			url = URI(api[:url])
			req = Net::HTTP::Get.new(url)
			accept = api[:accept] || "*/*"
			req.add_field("Accept", accept)
			res = Net::HTTP.new(url.host, url.port).start do |http|
				http.request(req)
			end
			return api[:success].nil? ? res.body : api[:success].call(res.body)
		end
	end
end

def chatbot(message)
	# If message is not matched then send to chatbot api.
	message = message.gsub('<@U3EPYT17G>', '').gsub('<@U3CUMAPE2>', '').rchomp(" ").chomp(" ")
	url_message = URI::encode(message)
	uri = URI::HTTP.build([nil, "10.0.0.50", 5000, nil, "message=#{url_message}", nil])
	puts uri.inspect
	req = Net::HTTP::Get.new(uri)
	req.add_field("Accept", "application/json")
	res = Net::HTTP.new(uri.host, uri.port).start do |http|
		http.request(req)
	end
	reply = eval(res.body)[:message].gsub(" ' ", "'").gsub(" .", ".")
	open('chat_log.txt', 'a') { |f|
	  f.puts Time.now.to_s + " " + message + " >>> " + reply
	}
	return reply
end

def get_log()
	chat_log = File.readlines('chat_log.txt')
	print_as_file(chat_log, 'chat_log.tmp', 'chat_log.txt', '')
end

test_proc = Proc.new { |input| "Test successful. You said: `#{input}`" }
api_call_proc = Proc.new { |input| api_call(input) }
analytics_proc = Proc.new { |input| get_analytics(input) }
intersect_proc = Proc.new { |input| get_intersection(input) }
tweet_proc = Proc.new { |input| get_tweets(input) }
url_list_proc = Proc.new { |input| manage_url_list(input) }
help_proc = Proc.new { |input| list_commands() }
chatbot_proc = Proc.new { |input| chatbot(input) }
get_log_proc = Proc.new { |input| get_log() }

#These matches only apply when a message contains @wafflebot
dm_message_maps = [
	{'matches': [/analy/i,], 'replies': [analytics_proc]}, #Match analytics or analyze
	# {'matches': [/intersection/i, /connection/i], 'replies': [intersect_proc]},
	{'matches': [/watch/i], 'replies': [url_list_proc]},
	{'matches': [/get tweet/i, /get twitter/i], 'replies': [tweet_proc]},
	{'matches': [/help/i], 'replies': [help_proc]},
	{'matches': [/get log/i], 'replies': [get_log_proc]},
	{'matches': [/.*/i], 'replies': [chatbot_proc]}
	# {'matches': [/test/i], 'replies': [test_proc]}
	# {'matches': [/i love you/i], 'replies': ['I love you too <@#{data["user"]}>']},
	# {'matches': [/^<@U3CUMAPE2>$/], 'replies': ["You said my name!", "That's my name!", "Yes master?"]}
]

#These messages will match on any comment
general_message_maps = [
	{'matches': [/pancake/i], 'replies': ["I hate pancakes.", "They serve pancakes in hell."]},
	# {'matches': [/the hell/i], 'replies': ["They serve pancakes in hell."]},
	{'matches': [/ron swanson/i], 'replies': [api_call_proc]},
	{'matches': [/foaas/i], 'replies': [api_call_proc]}
]


$client.on :message do |data|
	message =  data['text']
	message_is_matched = false
	$channel = data['channel']
	if message.match Regexp.union([/<@U3CUMAPE2>/, /<@U3EPYT17G>/]) #1st: team awesome, 2nd: bot_autonomy
		dm_message_maps.each do | map |
			if message.match Regexp.union(map[:matches])
				reply = map[:replies].sample
				text = (reply.is_a? Proc) ? reply.call(message) : eval('"' + reply + '"')
				$client.message channel: data['channel'], text: text
				message_is_matched = true
				break
			end
		end
		if !message_is_matched
			$client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, what?"
		end
	else
		if !message_is_matched
			general_message_maps.each do | map |
				if message.match Regexp.union(map[:matches])
					reply = map[:replies].sample
					text = (reply.is_a? Proc) ? reply.call(message) : eval('"' + reply + '"')
					$client.message channel: data['channel'], text: text
					message_is_matched = true
					break
				end
			end
		end
	end
		
end
class String
  def rchomp(sep = $/)
    self.start_with?(sep) ? self[sep.size..-1] : self
  end
end
$client.start!
