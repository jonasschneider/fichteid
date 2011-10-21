require 'bundler'
Bundler.require :default
$:.unshift File.expand_path 'lib'

require './app/app'

run Fichteid::App