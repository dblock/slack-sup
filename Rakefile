require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'app'

require 'tasks/logger'

import "tasks/#{ENV['RACK_ENV'] || 'development'}.rake"
