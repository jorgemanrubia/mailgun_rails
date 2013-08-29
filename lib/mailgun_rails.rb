require 'action_mailer'
require 'json'


Dir[File.dirname(__FILE__) + '/mailgun/*.rb'].each {|file| require file }

module Mailgun
end
