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

    def deliver!(email)
      mailgun_message = {
          :from => email.from,
          :to => email.to,
          :subject => email.subject,
          :html => email.body
      }

      mailgun_message['h:Reply-To'] = email.reply_to
      email.mailgun_variables.try(:each) do |name, value|
        mailgun_message["v:#{name}"] = value
      end

      mailgun_message['recipient-variables'] = email.mailgun_recipient_variables.to_json

      MailgunClient.send_message mailgun_message
    end
  end
end

ActionMailer::Base.add_delivery_method :mailgun, Mailgun::Deliverer