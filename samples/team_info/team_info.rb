#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'dotenv/load'
require 'hyperclient'

team_id = ENV['SUP_TEAM_ID'] || raise('missing SUP_TEAM_ID')
api_token = ENV['SUP_API_TOKEN'] || raise('missing SUP_API_TOKEN')

url = ENV['SUP_URL'] || 'https://sup.playplay.io/api'

client = Hyperclient.new(url) do |config|
  config.headers['X-Access-Token'] = api_token
end

team = client.team(id: team_id)

puts "sup team id: #{team.id}"
puts "sup team name: #{team.name}"

puts "sup team channels (#{team.channels.count})"

team.channels.each do |channel|
  puts "channel id: #{channel.id}"
  puts " channel slack id: #{channel.channel_id}"
  puts " sup day of week: #{channel.sup_wday}"
  puts " sup followup day: #{channel.sup_followup_wday}"
  puts " sup day: #{channel.sup_day}"
  puts " sup timezone: #{channel.sup_tz}"
  puts " sup time of day: #{channel.sup_time_of_day_s}"
  puts " sup every N weeks: #{channel.sup_every_n_weeks}"
  puts " sup size: #{channel.sup_size}"

  puts " channel users (#{channel.users.count}): #{channel.users.take(3).map(&:real_name).to_a.join(', ')}, ..."
end
