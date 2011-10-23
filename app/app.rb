require 'fichteid/ldap_user'

require 'openssl'
require 'base64'

module Fichteid
  class App < ::Hancock::SSO::App
    set :root, File.expand_path(File.dirname(__FILE__))
    set :haml, :format => :html5
    
    if ENV['SESSION_SECRET']
      use Rack::Session::Cookie, :secret => ENV['SESSION_SECRET']
    else
      puts "WARNING: No session secret set by ENV['SESSION_SECRET']"
      use Rack::Session::Cookie
    end
    
    use Rack::Flash
    
    set :authentication_delegate, Fichteid::LdapUser
    
    if ENV['HMAC_SECRET']
      set :hmac_secret, ENV['HMAC_SECRET']
    else
      puts "WARNING: No HMAC secret set by ENV['HMAC_SECRET']"
      set :hmac_secret, 'mypw'
    end
    
    def authorize_openid_request!
      if params['openid.return_to']
        signature = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), settings.hmac_secret, params['openid.return_to'].to_s)
        unless Base64.urlsafe_encode64(signature) == params['return_url_signature']
          halt 401, 'Invalid signature' 
        end
      end
    end
    
    def unauthenticated!
      flash.now[:error] = 'Benutzername oder Passwort falsch.' if params['failed_auth']
      halt haml :login_form
    end
    
    def section(key, *args, &block)
      @sections ||= Hash.new{ |k,v| k[v] = [] }
      if block_given?
        @sections[key] << block
      else
        @sections[key].inject(''){ |content, block| content << capture_haml(&block) } if @sections.keys.include?(key)
      end
    end
    
    get '/' do
      clear_return_to!
      haml :index
    end
  end
end