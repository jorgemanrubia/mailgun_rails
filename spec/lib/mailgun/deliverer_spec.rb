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

    def self.basic_multipart_mail_message
      Mail::Message.new(common_message_properties.merge(content_type: 'multipart/alternative')) do
        html_part do
          body '<span>the html content</span>'
        end

        text_part do
          body 'the text content'
        end
      end
    end

    def self.basic_html_message
      Mail::Message.new(common_message_properties.merge(content_type: 'text/html', body: '<span>the html content</span>'))
    end

    def self.basic_text_message
      Mail::Message.new(common_message_properties.merge(content_type: 'text/plain', body: 'the text content'))
    end

    def self.common_message_properties
      {from: 'from@email.com', to: 'to@email.com', subject: 'some subject', reply_to: 'reply@to.com', }
    end

    def self.message_with_mailgun_variables
      message = basic_multipart_mail_message
      message.mailgun_variables = {foo: 'bar'}
      message
    end

    def self.message_with_mailgun_recipient_variables
      message = basic_multipart_mail_message
      message.mailgun_recipient_variables = {foo: 'bar'}
      message
    end

    def self.basic_expected_mailgun_message_properties
      {
          :from => basic_multipart_mail_message.from,
          :to => basic_multipart_mail_message.to,
          :subject => basic_multipart_mail_message.subject,
          'h:Reply-To' => basic_multipart_mail_message.reply_to,
          :text => 'the text content',
          :html => '<span>the html content</span>'
      }
    end

    it_should_invoke_mailgun_message basic_multipart_mail_message, basic_expected_mailgun_message_properties

    it_should_invoke_mailgun_message message_with_mailgun_variables, basic_expected_mailgun_message_properties.merge('v:foo' => 'bar')

    it_should_invoke_mailgun_message basic_html_message, basic_expected_mailgun_message_properties.except(:text)

    it_should_invoke_mailgun_message basic_text_message, basic_expected_mailgun_message_properties.except(:html)
  end
end