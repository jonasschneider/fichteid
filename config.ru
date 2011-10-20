require 'bundler'
Bundler.require :default

require 'hancock'
$:.unshift File.expand_path 'lib'
require './app/app'

run Fichteid::App