module Mailgun
  class Deliverer

    attr_accessor :settings

    def initialize(settings)
      self.settings = settings
    end

    def domain
      self.settings[:domain]
    end

    def api_key
      self.settings[:api_key]
    end

    def deliver!(rails_message)
      domain_override = rails_message['X-Domain-Override']
      mailgun_client(domain_override).send_message build_mailgun_message_for(rails_message)
    end

    private

    def build_mailgun_message_for(rails_message)
      mailgun_message = build_basic_mailgun_message_for rails_message
      transform_mailgun_attributes_from_rails rails_message, mailgun_message
      remove_empty_values mailgun_message

      mailgun_message
    end

    def transform_mailgun_attributes_from_rails(rails_message, mailgun_message)
      transform_email_headers rails_message, mailgun_message
      transform_mailgun_variables rails_message, mailgun_message
      transform_mailgun_recipient_variables rails_message, mailgun_message
      transform_custom_headers rails_message, mailgun_message
    end

    def build_basic_mailgun_message_for(rails_message)
      mailgun_message = {
        :from => rails_message[:from].formatted, 
        :to => rails_message[:to].formatted, 
        :subject => rails_message.subject,
        :html => extract_html(rails_message), 
        :text => extract_text(rails_message),
        :attachment => []
      }

      # RestClient requires attachments to be in file format, use a temp directory and the decoded attachment
      rails_message.attachments.each do |attachment|
        # file needs its original name
        fname = "#{Dir.tmpdir}/#{attachment.filename}"

        # write the file to temp
        File.open(fname, 'wb') {|f| f.write(attachment.decoded)}

        # then add as a file object
        mailgun_message[:attachment] << File.new(fname)
      end

      return mailgun_message
    end

    def transform_email_headers(rails_message, mailgun_message)
      mailgun_message['h:Reply-To'] = rails_message.reply_to.first if rails_message.reply_to
      mailgun_message['h:Message-ID'] = rails_message.message_id if rails_message.message_id
    end

    # @see http://stackoverflow.com/questions/4868205/rails-mail-getting-the-body-as-plain-text
    def extract_html(rails_message)
      if rails_message.html_part
        rails_message.html_part.body.decoded
      else
        rails_message.content_type =~ /text\/html/ ? rails_message.body.decoded : nil
      end
    end

    def extract_text(rails_message)
      if rails_message.multipart?
        rails_message.text_part ? rails_message.text_part.body.decoded : nil
      else
        rails_message.content_type =~ /text\/plain/ ? rails_message.body.decoded : nil
      end
    end

    def transform_mailgun_variables(rails_message, mailgun_message)
      rails_message.mailgun_variables.try(:each) do |name, value|
        mailgun_message["v:#{name}"] = value
      end
    end

    def transform_custom_headers(rails_message, mailgun_message)
      rails_message.mailgun_headers.try(:each) do |name, value|
        mailgun_message["h:#{name}"] = value
      end
    end

    def transform_mailgun_recipient_variables(rails_message, mailgun_message)
      mailgun_message['recipient-variables'] = rails_message.mailgun_recipient_variables.to_json if rails_message.mailgun_recipient_variables
    end

    def remove_empty_values(mailgun_message)
      mailgun_message.delete_if { |key, value| value.nil? }
    end

    def mailgun_client(domain_override = nil)
      @maingun_client ||= Client.new(api_key, domain_override || domain)
    end
  end
end

ActionMailer::Base.add_delivery_method :mailgun, Mailgun::Deliverer
