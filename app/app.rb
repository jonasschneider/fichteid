module Fichteid
  class App < ::Hancock::SSO::App
    set :root, File.expand_path(File.dirname(__FILE__))
    set :haml, :format => :html5
    
    def unauthenticated!
      halt haml :login_form
    end
    
    get '/' do
      haml 'hallo fichte'
    end
  end
end