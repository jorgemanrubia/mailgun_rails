module MailgunRails
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

    def verify_ssl
      #default value = true
      self.settings[:verify_ssl] != false
    end

    def deliver!(rails_message)
      response = mailgun_client.send_message build_mailgun_message_for(rails_message)
      if response.code == 200
        mailgun_message_id = JSON.parse(response.to_str)["id"]
        rails_message.message_id = mailgun_message_id
      end
      response
    end

    private

    def build_mailgun_message_for(rails_message)
      mailgun_message = build_basic_mailgun_message_for rails_message
      transform_mailgun_attributes_from_rails rails_message, mailgun_message
      remove_empty_values mailgun_message

      mailgun_message
    end

    def transform_mailgun_attributes_from_rails(rails_message, mailgun_message)
      transform_reply_to rails_message, mailgun_message if rails_message.reply_to
      transform_mailgun_variables rails_message, mailgun_message
      transform_mailgun_options rails_message, mailgun_message
      transform_mailgun_recipient_variables rails_message, mailgun_message
      transform_custom_headers rails_message, mailgun_message
    end

    def build_basic_mailgun_message_for(rails_message)
      mailgun_message = {
       from: rails_message[:from].formatted,
       to: rails_message[:to].formatted,
       subject: rails_message.subject,
       html: extract_html(rails_message),
       text: extract_text(rails_message)
      }

      [:cc, :bcc].each do |key|
        mailgun_message[key] = rails_message[key].formatted if rails_message[key]
      end

      return mailgun_message if rails_message.attachments.empty?

      # RestClient requires attachments to be in file format, use a temp directory and the decoded attachment
      mailgun_message[:attachment] = []
      mailgun_message[:inline] = []
      rails_message.attachments.each do |attachment|
        # then add as a file object
        if attachment.inline?
          mailgun_message[:inline] << MailgunRails::Attachment.new(attachment, encoding: 'ascii-8bit', inline: true)
        else
          mailgun_message[:attachment] << MailgunRails::Attachment.new(attachment, encoding: 'ascii-8bit')
        end
      end

      return mailgun_message
    end

    def transform_reply_to(rails_message, mailgun_message)
      mailgun_message['h:Reply-To'] = rails_message[:reply_to].formatted.first
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

    def transform_mailgun_options(rails_message, mailgun_message)
      rails_message.mailgun_options.try(:each) do |name, value|
        mailgun_message["o:#{name}"] = value
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
      mailgun_message.delete_if { |key, value| value.nil? or
                                               value.respond_to?(:empty?) && value.empty? }
    end

    def mailgun_client
      @maingun_client ||= Client.new(api_key, domain, verify_ssl)
    end
  end
end

ActionMailer::Base.add_delivery_method :mailgun, MailgunRails::Deliverer
