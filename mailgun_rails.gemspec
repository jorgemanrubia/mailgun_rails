$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mailgun/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mailgun_rails"
  s.version     = Mailgun::VERSION
  s.authors     = ["Jorge Manrubia"]
  s.email       = ["jorge.manrubia@gmail.com"]
  s.homepage    = "http://jorgemanrubia.net"
  s.summary     = "Rails Action Mailer adapter for Mailgun"
  s.description = "An adapter for using Mailgun with Rails and Action Mailer"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "rest-client", "~> 1.6.7"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec", '~> 2.14.1'
end
