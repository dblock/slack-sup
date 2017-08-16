require 'rubygems'
require 'bundler'

Bundler.setup :default, :development

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'slack-sup'

require 'tasks/logger'

import "tasks/#{ENV['RACK_ENV'] || 'development'}.rake"
import 'tasks/cron.rake'
