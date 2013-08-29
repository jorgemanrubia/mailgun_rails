# rails_mailgun

*rails_mailgun* is an Action Mailer adapter for using [Mailgun](http://www.mailgun.com/) in Rails apps.

## Installing

In your `Gemfile`

```ruby
gem 'rails_mailgun'
```

## Usage

To configure your Mailgun credentials place the following code in the corresponding environment file (`development.rb`, `production.rb`...)

```ruby
config.action_mailer.delivery_method = :mailgun
ActionMailer::Base.mailgun_settings = {
		api_key: '<mailgun api key>',
		domain: '<mailgun domain>'
}
```

Now you can send emails using plain Action Mailer:

```ruby
mail from: 'sender@email.com', to: 'receiver@email.com', subject: 'this is an email'
```

### Sending Mailgun variables

You can [attach variables to your messages](http://documentation.mailgun.com/user_manual.html#attaching-data-to-messages) that will be included in Mailgun webhooks:

```ruby
email = mail(...)
email.mailgun_variables = {name_1: :value_1, :name_2 => value_2}
```

### Sending Recipient Variables

Mailgun supports [Batch sending](http://documentation.mailgun.com/user_manual.html#batch-sending) using *recipient variables*. To define recipient variables:

```ruby
email = mail(...)
email.mailgun_recipient_variables = {'user_1@email.com': {id: 1}, 'user_2@email.com': {id: 2}}
```

### Pending

 - Sending attachments


