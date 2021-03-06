#!/usr/bin/env ruby

require 'rubygems'
require 'mqtt/client'
require 'net/http'
require 'json'


raise "Error: PACHUBE_API_KEY is not set" if ENV['PACHUBE_API_KEY'].nil? 

def update_datastream_value(feed, datastream, value)
  uri = URI.parse("http://api.pachube.com/v2/feeds/#{feed}/datastreams/#{datastream}")

  begin
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      http.open_timeout = 10
      req = Net::HTTP::Put.new(uri.request_uri)
      req['X-PachubeApiKey'] = ENV['PACHUBE_API_KEY']
      req['Content-Type'] = 'application/json'
      req.body = {'current_value' => value}.to_json
      http.request(req)
    end
    puts " * #{response.message}"
  rescue Timeout::Error
    puts " * Timeout"
  end
end


# Make STDOUT unbuffered, so that it appears in the log immediately
STDOUT.sync = true


client = MQTT::Client.new('localhost')
client.connect do
  client.subscribe('/1wire/#')
  loop do
    topic,message = client.get
    puts "#{topic}: #{message}"
    
    if topic == '/1wire/28537FEE02000078/temperature'
      update_datastream_value(42662, 1, message)
    end
  end
end
