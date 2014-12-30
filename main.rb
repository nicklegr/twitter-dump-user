#!ruby -Ku
# coding: utf-8

require 'pp'
require 'yaml'
require 'twitter'
require 'pry'
require 'pry-nav'

yaml = YAML.load_file('config.yaml')

target = yaml['target']

client = Twitter::REST::Client.new do |config|
  config.consumer_key = yaml['consumer_key']
  config.consumer_secret = yaml['consumer_secret']
  config.access_token = yaml['oauth_token']
  config.access_token_secret = yaml['oauth_token_secret']
end

def collect_with_max_id(collection=[], max_id=nil, &block)
  response = yield(max_id)
  collection += response
  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
end

def client.get_all_tweets(user)
  collect_with_max_id do |max_id|
    options = {count: 200, include_rts: true, trim_user: true}
    options[:max_id] = max_id unless max_id.nil?
    user_timeline(user, options)
  end
end

def client.get_all_favorites(user)
  collect_with_max_id do |max_id|
    sleep 61 # rate limit is 15req / 15min

    options = {count: 200}
    options[:max_id] = max_id unless max_id.nil?
    favorites(user, options)
  end
end

user = client.user(target).to_hash

statuses = client.get_all_tweets(target)
statuses.map! { |e| e.to_hash }

favorites = client.get_all_favorites(target)
favorites.map! { |e| e.to_hash }

friends = client.friends(target, {count: 200, skip_status: true, include_user_entities: true})
friends = friends.to_a.map { |e| e.to_hash }

followers = client.followers(target, {count: 200, skip_status: true, include_user_entities: true})
followers = followers.to_a.map { |e| e.to_hash }

data = {
  'user' => user,
  'statuses' => statuses,
  'favorites' => favorites,
  'friends' => friends,
  'followers' => followers,
}

puts data.to_yaml
