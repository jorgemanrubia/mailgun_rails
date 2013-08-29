require 'spec_helper'
require 'mailgun/deliverer'
require 'mailgun/client'
require 'json'


describe Mailgun::Deliverer do
  describe "#deliver" do
    let(:api_key) { :some_api_key }
    let(:domain) { :some_domain }
    let(:mailgun_client) { double(Mailgun::Client) }

    before(:each) do
      Mailgun::Client.stub(:new).with(api_key, domain).and_return mailgun_client
    end

    def self.it_should_invoke_mailgun_message(email, expected_mailgun_properties)
      it "should invoke the mailgun client providing #{expected_mailgun_properties} when receiving #{email.inspect}" do
        mailgun_client.should_receive(:send_message).with(expected_mailgun_properties)
        Mailgun::Deliverer.new(api_key: api_key, domain: domain).deliver!(email)
      end
    end

    def self.basic_mail_message
      Mail::Message.new(from: 'from@email.com', to: 'to@email.com', subject: 'some subject', body: 'the html body', reply_to: 'reply@to.com')
    end

    def self.message_with_mailgun_variables
      message = basic_mail_message
      message.mailgun_variables = {foo: 'bar'}
      message
    end

    def self.message_with_mailgun_recipient_variables
      message = basic_mail_message
      message.mailgun_recipient_variables = {foo: 'bar'}
      message
    end

    def self.basic_expected_mailgun_message_properties
      {
          :from => basic_mail_message.from,
          :to => basic_mail_message.to,
          :subject => basic_mail_message.subject,
          'h:Reply-To' => basic_mail_message.reply_to,
          :html => basic_mail_message.body.to_s
      }
    end

    it_should_invoke_mailgun_message basic_mail_message, basic_expected_mailgun_message_properties

    it_should_invoke_mailgun_message message_with_mailgun_variables, basic_expected_mailgun_message_properties.merge('v:foo' => 'bar')

    it_should_invoke_mailgun_message message_with_mailgun_recipient_variables, basic_expected_mailgun_message_properties.merge('recipient-variables' => {foo: 'bar'}.to_json)
  end
end