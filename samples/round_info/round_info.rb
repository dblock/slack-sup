#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'dotenv/load'
require 'hyperclient'
require 'time_ago_in_words'

require 'action_view'
require 'action_view/helpers'
include ActionView::Helpers::DateHelper

team_id = ENV['SUP_TEAM_ID'] || raise('missing SUP_TEAM_ID')
api_token = ENV['SUP_API_TOKEN'] || raise('missing SUP_API_TOKEN')

url = 'https://sup.playplay.io/api'

client = Hyperclient.new(url) do |config|
  config.headers['X-Access-Token'] = api_token
end

team = client.team(id: team_id)

puts "sup team id: #{team.id}"
puts "sup team name: #{team.name}"
puts "sup team rounds: #{team.rounds.count}"

team.rounds.to_a[0...-1].each do |round|
  puts "round #{time_ago_in_words(DateTime.parse(round.created_at))} ago, #{round.sups.count} sup(s)"
end

last_round = team.rounds.to_a.last
puts "last round #{time_ago_in_words(DateTime.parse(last_round.created_at))} ago, #{last_round.sups.count} sup(s)"

last_round.sups.each do |sup|
  puts " #{sup.users.map(&:real_name).join(', ')}: #{sup.try(:outcome) || 'n/a'}"
end
