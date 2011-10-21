require 'bundler'
Bundler.require :default

require 'hancock'
$:.unshift File.expand_path 'lib'
require './app/app'

class MyUserClass
  def self.authenticated?(username, password)
    #username == 'atmos' && password == 'hancock'
    true
  end
end

Hancock::User.authentication_class = MyUserClass

run Fichteid::App