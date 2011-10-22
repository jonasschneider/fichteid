module Hancock
  module Matchers
    class RedirectToConsumer
      include RSpec::Matchers
      include Webrat::Methods
      include Webrat::Matchers

      def initialize(consumer_url, username)
        @consumer_url, @username = consumer_url, username
        @identity_url = "http://example.org/sso/users/#{username}"
      end

      def matches?(target)
        target.status.should == 302

        redirect_params = Addressable::URI.parse(target.headers['Location']).query_values

        redirect_params['openid.ns'].should               == 'http://specs.openid.net/auth/2.0'
        redirect_params['openid.mode'].should             == 'id_res'
        redirect_params['openid.return_to'].should        == @consumer_url
        redirect_params['openid.assoc_handle'].should     =~ /^\{HMAC-SHA1\}\{[^\}]{8}\}\{[^\}]{8}\}$/
        redirect_params['openid.op_endpoint'].should      == 'http://example.org/sso'
        redirect_params['openid.claimed_id'].should       == @identity_url
        redirect_params['openid.identity'].should         == @identity_url

        redirect_params['openid.sreg.username'].should    == @username

        redirect_params['openid.sig'].should_not be_nil
        redirect_params['openid.signed'].should_not be_nil
        redirect_params['openid.response_nonce'].should_not be_nil
        true
      end

      def failure_message
        puts "Expected a redirect to the consumer"
      end
    end

    def be_a_redirect_to_the_consumer(consumer_url, username)
      RedirectToConsumer.new(consumer_url, username)
    end
  end
end
