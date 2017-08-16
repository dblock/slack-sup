require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

import "tasks/#{ENV['RACK_ENV'] || 'development'}.rake"
