require 'spec_helper'
require 'mailgun/client'

describe Mailgun::Client do
  let(:client){ Mailgun::Client.new(:some_api_key, :some_domain) }
  let(:rest_client) { double(RestClient::Request) }

  describe "#send_message" do
    it 'should make a POST rest request passing the parameters to the mailgun end point' do
      expected_url = "https://api:some_api_key@api.mailgun.net/v3/some_domain/messages"
      RestClient::Request.stub(:execute).with({ method: :post, url: expected_url, payload: { foo: :bar }, verify_ssl: true})
      client.send_message foo: :bar
    end
  end
end
