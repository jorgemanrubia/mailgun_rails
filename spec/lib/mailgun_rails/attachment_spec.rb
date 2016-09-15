require 'spec_helper'
require 'mailgun_rails/attachment'

describe MailgunRails::Attachment do
  describe "#send_message" do
    before do
      @mail = Mail.new()
      @mail.attachments["attachment.png"] = "\312\213\254\232"
      @mail.attachments.inline["attachment2.png"] = "\312\213\254\232"
      @mail.attachments["attachment.json"] = { mime_type: 'application/json', content: {cool: 'json'}.to_json }

    end

    it 'should respond to rest_client api' do
      attachment = MailgunRails::Attachment.new(@mail.attachments.first)
      attachment.respond_to?(:path).should eq(true)
      attachment.respond_to?(:original_filename).should eq(true)
      attachment.respond_to?(:content_type).should eq(true)
      attachment.respond_to?(:read).should eq(true)
    end

    it 'should set cid as original_filename' do
      attachment = MailgunRails::Attachment.new(@mail.attachments.inline.first, inline: true)
      attachment.original_filename.should eq(@mail.attachments.inline.first.cid)
    end

    it 'should set filename as original_filename' do
      attachment = MailgunRails::Attachment.new(@mail.attachments.first)
      attachment.original_filename.should eq(@mail.attachments.first.filename)
    end

    it 'should set filename as original_filename for hash' do
      attachment = MailgunRails::Attachment.new(@mail.attachments.last)
      attachment.original_filename.should eq(@mail.attachments.last.filename)
    end
  end
end
