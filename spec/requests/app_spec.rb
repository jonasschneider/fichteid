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
