#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'dotenv/load'
require 'hyperclient'

team_id = ENV['SUP_TEAM_ID'] || raise('missing SUP_TEAM_ID')
api_token = ENV['SUP_API_TOKEN'] || raise('missing SUP_API_TOKEN')

url = 'https://sup.playplay.io/api'

client = Hyperclient.new(url) do |config|
  config.headers['X-Access-Token'] = api_token
end

team = client.team(id: team_id)

puts "sup team id: #{team.id}"
puts "sup team name: #{team.name}"
puts "sup day of week: #{team.sup_wday}"
puts "sup followup day: #{team.sup_followup_wday}"
puts "sup day: #{team.sup_day}"
puts "sup timezone: #{team.sup_tz}"
puts "sup time of day: #{team.sup_time_of_day_s}"
puts "sup every N weeks: #{team.sup_every_n_weeks}"
puts "sup size: #{team.sup_size}"

puts "sup team users: #{team.users.take(3).map(&:real_name).to_a.join(', ')}, ..."
