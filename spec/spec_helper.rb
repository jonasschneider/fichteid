require 'pp'
require 'rubygems'
require 'bundler'
project_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

Bundler.require :default, :test

require File.expand_path(File.join('..', '..', 'app', 'app'), __FILE__)

require File.join(project_root, 'spec', 'helpers', 'matchers')

Webrat.configure do |config|
  config.mode = :rack
  config.application_framework = :sinatra
  config.application_port = 4567
end

class MyUserClass
  def self.authenticated?(username, password)
    if username == 'atmos' && password == 'hancock'
      { username: 'atmos', name: 'Atmos', group_ids: '' } 
    else
      false
    end
  end
end

Rspec.configure do |config|
  def app
    Fichteid::App.configure do |app|
      app.set :authentication_delegate, MyUserClass
    end
  end

  def login(username, password)
    post '/sso/login', :username => username, :password => password
  end

  config.include(Rack::Test::Methods)
  config.include(Webrat::Methods)
  config.include(Webrat::Matchers)
  config.include(Hancock::Matchers)
end
