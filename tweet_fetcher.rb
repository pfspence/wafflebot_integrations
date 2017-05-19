require 'twitter'

class TweetFetcher
	attr_accessor :user
	attr_accessor :count

	def initialize(user, count)
		@user = user
		@count = count
	end

	$twitter_client = Twitter::REST::Client.new do |config|
	  config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
	  config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
	  config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
	  config.access_token_secret = ENV["TWITTER_ACCESS_SECRET"]
	end

	# def collect_with_max_id(collection=[], max_id=nil, &block)
	#   response = yield(max_id)
	#   collection += response
	#   response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
	# end

	def get_tweets(user, limit)
		# return collect_with_max_id do |max_id|
		# 	options = {count: count, include_rts: true}
		# 	options[:max_id] = max_id unless max_id.nil?
		# 	# puts options.inspect
		# 	$twitter_client.user_timeline(user, options)
		# end
		tweets = []
		while limit > 0
			count = limit < 200 ? limit : 200
			options = {count: count, include_rts: true}
			options[:max_id] = tweets.last.id unless tweets.empty?

			tweets.concat($twitter_client.user_timeline(user, options))
			limit = limit - 200
		end
		# puts tweets.last.text
		return tweets.map do |tweet|
			tweet.text
		end
	  # options = {:count=> @count}
	  # $client.user_timeline(@user, options)
	end

	public def fetch()
		get_tweets(@user, @count)
	end
end
