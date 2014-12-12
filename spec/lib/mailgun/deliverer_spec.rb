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

    it 'should invoke mailgun message transforming the basic email properties' do
      check_mailgun_message basic_multipart_rails_message, basic_expected_mailgun_message
    end

    it 'should invoke mailgun message transforming the mail gun variables' do
      check_mailgun_message message_with_mailgun_variables, basic_expected_mailgun_message.merge('v:foo' => 'bar')
    end

    it 'should invoke mailgun message transforming the mailgun options' do
      check_mailgun_message message_with_mailgun_options, basic_expected_mailgun_message.merge('o:foo' => 'bar')
    end

    it 'should invoke mailgun message transforming the custom headers' do
      check_mailgun_message message_with_custom_headers, basic_expected_mailgun_message.merge('h:foo' => 'bar')
    end

    it 'should invoke mailgun message transforming the recipient variables' do
      check_mailgun_message message_with_mailgun_recipient_variables, basic_expected_mailgun_message.merge('recipient-variables' => {foo: 'bar'}.to_json)
    end

    it 'should send HTML only messages' do
      check_mailgun_message html_rails_message, basic_expected_mailgun_message.except(:text)
    end

    it 'should send text only messages' do
      check_mailgun_message text_rails_message, basic_expected_mailgun_message.except(:html)
    end

    it 'should include sender and recipient names in from field' do
      check_mailgun_message text_rails_message_with_names, basic_expected_mailgun_message.except(:html).merge(emails_with_names)
    end

    it 'should include reply-to name in custom header' do
      msg = Mail::Message.new(to: 'to@email.com',
                              from: 'from@email.com',
                              reply_to: 'Reply User <replyto@email.com>')
      expectation = { to: ['to@email.com'],
                      from: ['from@email.com'],
                      'h:Reply-To' => 'Reply User <replyto@email.com>' }
      check_mailgun_message msg, expectation
    end


    it 'should include attachment' do
      rails_message = rails_message_with_attachment
      attachment = double(Mailgun::Attachment)
      Mailgun::Attachment.stub(:new).with(rails_message.attachments.first, encoding: 'ascii-8bit').and_return attachment
      expectation = basic_expected_mailgun_message.merge({inline: []})
      expectation[:attachment] = [attachment]
      check_mailgun_message rails_message, expectation
    end

    it 'should include inline attachment' do
      rails_message = rails_message_with_inline_attachment
      attachment = double(Mailgun::Attachment)
      Mailgun::Attachment.stub(:new).with(rails_message.attachments.first, encoding: 'ascii-8bit', inline: true).and_return attachment
      expectation = basic_expected_mailgun_message.merge({attachment: []})
      expectation[:inline] = [attachment]
      check_mailgun_message rails_message, expectation
    end

    it 'should include attachment of both types' do
      rails_message = rails_message_with_both_types_attachments
      attachment = double(Mailgun::Attachment)
      Mailgun::Attachment.stub(:new).with(rails_message.attachments.first, encoding: 'ascii-8bit', inline: true).and_return attachment
      Mailgun::Attachment.stub(:new).with(rails_message.attachments.last, encoding: 'ascii-8bit').and_return attachment
      expectation = basic_expected_mailgun_message
      expectation[:inline] = [attachment]
      expectation[:attachment] = [attachment]
      check_mailgun_message rails_message, expectation
    end

    def check_mailgun_message(rails_message, mailgun_message)
      mailgun_client.should_receive(:send_message).with(mailgun_message)
      Mailgun::Deliverer.new(api_key: api_key, domain: domain).deliver!(rails_message)
    end

    def rails_message_with_attachment
      msg = basic_multipart_rails_message
      msg.attachments["attachment.jpg"] = "\312\213\254\232"
      msg
    end

    def rails_message_with_inline_attachment
      msg = basic_multipart_rails_message
      msg.attachments.inline["attachment.jpg"] = "\312\213\254\232"
      msg
    end

    def rails_message_with_both_types_attachments
      msg = basic_multipart_rails_message
      msg.attachments.inline["attachment.jpg"] = "\312\213\254\232"
      msg.attachments["attachment.png"] = "\312\213\254\232"
      msg
    end

    def basic_multipart_rails_message
      this_example = self
      Mail::Message.new(common_rails_message_properties.merge(content_type: 'multipart/alternative')) do
        html_part do
          body this_example.html_body
        end

        text_part do
          body this_example.text_body
        end
      end
    end

    def html_rails_message
      Mail::Message.new(common_rails_message_properties.merge(content_type: 'text/html', body: html_body))
    end

    def text_rails_message
      Mail::Message.new(common_rails_message_properties.merge(content_type: 'text/plain', body: text_body))
    end

    def text_rails_message_with_names
      Mail::Message.new(common_rails_message_properties.merge(content_type: 'text/plain', body: text_body).merge(emails_with_names))
    end

    def emails_with_names
      {from: ['Sender <from@email.com>'], to: ['Receiver <to@email.com>', 'Another one <to2@email.com>']}
    end

    def common_rails_message_properties
      {from: 'from@email.com', to: 'to@email.com', subject: 'some subject', reply_to: 'reply@to.com', }
    end

    def message_with_mailgun_variables
      message = basic_multipart_rails_message
      message.mailgun_variables = {foo: 'bar'}
      message
    end

    def message_with_mailgun_options
      message = basic_multipart_rails_message
      message.mailgun_options = {foo: 'bar'}
      message
    end

    def message_with_custom_headers
      message = basic_multipart_rails_message
      message.mailgun_headers = {foo: 'bar'}
      message
    end

    def message_with_mailgun_recipient_variables
      message = basic_multipart_rails_message
      message.mailgun_recipient_variables = {foo: 'bar'}
      message
    end

    def basic_expected_mailgun_message
      {
          :from => [common_rails_message_properties[:from]],
          :to => [common_rails_message_properties[:to]],
          :subject => common_rails_message_properties[:subject],
          'h:Reply-To' => common_rails_message_properties[:reply_to],
          :text => text_body,
          :html => html_body
      }
    end
  end

  def html_body
    '<span>the html content</span>'
  end

  def text_body
    'the text content'
  end
end
