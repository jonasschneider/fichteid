require File.expand_path(File.dirname(__FILE__)+'/../spec_helper')

describe "visiting /sso/login" do
  describe 'with invalid credentials' do
    it "shows an error message" do
      post "/sso/login", username: nil, password: nil
      last_response.body.should =~ /falsch/
    end
  end
end