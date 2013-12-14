class SandboxMailer < ActionMailer::Base
  def sandbox
    mail from: 'some@email.com', to: 'jorge.manrubia@gmail.com', subject: 'this is an email'
  end
end