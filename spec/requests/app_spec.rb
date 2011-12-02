require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')
require File.expand_path(File.join('..', '..', '..', 'app', 'app'), __FILE__)

describe "visiting /sso" do
  let(:user)      { 'atmos' }
  let(:password)  { 'hancock' }
  let(:consumer_url) { "http://foo.example.org/" }
  let(:realm) { "http://foo.example.org" }
  let(:identity_url) { "http://example.org/sso/users/#{user}" }
  
  describe 'unauthenticated' do
    let(:params) do
      signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), 'mypw', consumer_url))
      
      {
        "openid.ns"         => "http://specs.openid.net/auth/2.0",
        "openid.mode"       => "checkid_setup",
        "openid.return_to"  => consumer_url,
        "openid.identity"   => identity_url,
        "openid.claimed_id" => identity_url,
        "openid.realm" => realm,
        "return_url_signature" => signature
      }
    end
    
    it "presents the requested realm" do
      get "/sso", params
      last_response.body.should =~ /#{realm}/
      
      module Fichteid
        module LdapUser
          def self.authenticated?(user, password)
            true
          end
        end
      end
      
      fill_in 'username', with: user
      fill_in 'password', with: password
      click_button 'Anmelden'
      follow_redirect!
      
      last_response.should be_a_redirect_to_the_consumer(consumer_url, user)
    end
  end

  describe "with an openid.return_to parameter as an authenticated user" do
    before :each do
      login(user, password)
    end
    
    describe "without signature (normal OpenID)" do
      let(:params) do
        {
          "openid.ns"         => "http://specs.openid.net/auth/2.0",
          "openid.mode"       => "checkid_setup",
          "openid.return_to"  => consumer_url,
          "openid.identity"   => identity_url,
          "openid.claimed_id" => identity_url,
          "openid.realm" => realm
        }
      end
      
      it "asks whether to redirect back" do
        get "/sso", params
        
        last_response.status.should == 200
        last_response.body.should =~ /#{realm}/
        
        click_button "Fortfahren"
        
        last_response.should be_a_redirect_to_the_consumer(consumer_url, user)
      end
      
      it "accept cancellation" do
        get "/sso", params
        
        click_button "Abbrechen"
        
        last_request.url.should == consumer_url
      end
    end
    
    it "works in integration" do
u = "/sso?openid.mode=checkid_setup&openid.identity=http%3a%2f%2fspecs.openid.net%2fauth%2f2.0%2fidentifier_select&openid.ns=http%3a%2f%2fspecs.openid.net%2fauth%2f2.0&openid.claimed_id=http%3a%2f%2fspecs.openid.net%2fauth%2f2.0%2fidentifier_select&openid.realm=http%3a%2f%2fwww.swedenintouch.se%2f&openid.return_to=http%3a%2f%2fwww.swedenintouch.se%2fTemplates%2fSignInOpenId.aspx%3fid%3d131%26token%3dGBjLQ3%252bJ4x0Lgqx2LZtHzh0pUZ9nLfshQBqlDA%252fW8P1odHRwOi8vc3BlY3Mub3BlbmlkLm5ldC9hdXRoLzIuMC9pZGVudGlmaWVyX3NlbGVjdA0KaHR0cDovL3NwZWNzLm9wZW5pZC5uZXQvYXV0aC8yLjAvaWRlbnRpZmllcl9zZWxlY3QNCmh0dHA6Ly9maWNodGVpZC5oZXJva3UuY29tL3Nzbw0KMi4wDQo%253d&openid.assoc_handle=%7bHMAC-SHA256%7d%7b4ed8f613%7d%7ba6SBpQ%3d%3d%7d&openid.ns.sreg=http%3a%2f%2fopenid.net%2fextensions%2fsreg%2f1.1&openid.sreg.required=&openid.sreg.optional=email%2cfullname%2cgender"
      get u
      click_button 'Fortfahren'
      last_response.should be_a_redirect_to_the_consumer("http://www.swedenintouch.se/Templates/SignInOpenId.aspx?id=131&token=GBjLQ3%2bJ4x0Lgqx2LZtHzh0pUZ9nLfshQBqlDA%2fW8P1odHRwOi8vc3BlY3Mub3BlbmlkLm5ldC9hdXRoLzIuMC9pZGVudGlmaWVyX3NlbGVjdA0KaHR0cDovL3NwZWNzLm9wZW5pZC5uZXQvYXV0aC8yLjAvaWRlbnRpZmllcl9zZWxlY3QNCmh0dHA6Ly9maWNodGVpZC5oZXJva3UuY29tL3Nzbw0KMi4wDQo%3d", user)
    end
    
    it "works in integration 2" do
      return_url = "http://titan:80/jonas/php-openid/examples/consumer/finish_auth.php?janrain_nonce=2011-12-02T17:26:31ZgrTN4x"
      opts = {
        "openid.ns"=>"http://specs.openid.net/auth/2.0", 
        "openid.ns.sreg"=>"http://openid.net/extensions/sreg/1.1", 
        "openid.ns.pape"=>"http://specs.openid.net/extensions/pape/1.0", "openid.sreg.required"=>"nickname", 
        "openid.sreg.optional"=>"fullname,email", "openid.pape.preferred_auth_policies"=>"", 
        "openid.realm"=>"http://titan:80/jonas/php-openid/examples/consumer/", "openid.mode"=>"checkid_setup", 
        "openid.return_to"=>return_url,
        "openid.identity"=>"http://specs.openid.net/auth/2.0/identifier_select", 
        "openid.claimed_id"=>"http://specs.openid.net/auth/2.0/identifier_select", 
        "openid.assoc_handle"=>"{HMAC-SHA1}{4ed90a41}{ybgdAw==}"
      }

      post '/sso', opts
      follow_redirect! # redirects to the GET aequivalent
      click_button 'Fortfahren'
      last_response.should be_a_redirect_to_the_consumer(return_url, user)
    end
    
    
    describe "with a correct signature" do
      let(:params) do
        signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), 'mypw', consumer_url))
        
        {
          "openid.ns"         => "http://specs.openid.net/auth/2.0",
          "openid.mode"       => "checkid_setup",
          "openid.return_to"  => consumer_url,
          "openid.identity"   => identity_url,
          "openid.claimed_id" => identity_url,
          
          "return_url_signature" => signature
        }
      end
      
      it "redirects back to the consumer app" do
        get "/sso", params
        last_response.should be_a_redirect_to_the_consumer(consumer_url, user)
      end
    end
    
    describe "with a bogus realm" do
      let(:params) do
        signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), 'mypw', consumer_url))
        
        {
          "openid.ns"         => "http://specs.openid.net/auth/2.0",
          "openid.mode"       => "checkid_setup",
          "openid.return_to"  => consumer_url,
          "openid.identity"   => identity_url,
          "openid.claimed_id" => identity_url,
          "openid.realm" => "http://google.com",
          "return_url_signature" => signature
        }
      end
      
      it "fails" do
        get "/sso", params
        last_response.status.should_not == 302
      end
    end
  end
  
end
