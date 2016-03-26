require 'spec_helper'
require 'mailgun/client'

describe Mailgun::Client do
  let(:client){Mailgun::Client.new(:some_api_key, :some_domain)}

  describe "#send_message" do
    it 'should make a POST rest request passing the parameters to the mailgun end point' do
      expected_url = "https://api:some_api_key@api.mailgun.net/v3/some_domain/messages"
      RestClient.should_receive(:post).with(expected_url, foo: :bar)
      client.send_message foo: :bar
    end

    it "should use custom set domain" do
      expected_url = "https://api:some_api_key@api.mailgun.net/v3/email.com/messages"
      RestClient.should_receive(:post).with(expected_url, foo: :bar)
      client.domain = "email.com"
      client.send_message foo: :bar
    end
  end
end
