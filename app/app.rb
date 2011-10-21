require 'fichteid/ldap_user'

module Fichteid
  class App < ::Hancock::SSO::App
    set :root, File.expand_path(File.dirname(__FILE__))
    set :haml, :format => :html5
    
    if ENV['SESSION_SECRET']
      use Rack::Session::Cookie, :secret => ENV['SESSION_SECRET']
    else
      puts "WARNING: No session secret set in ENV['SESSION_SECRET']"
      use Rack::Session::Cookie
    end
    
    set :authentication_delegate, Fichteid::LdapUser
    
    def unauthenticated!
      halt haml :login_form
    end
    
    get '/' do
      haml :index
    end
  end
end