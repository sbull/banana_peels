# BananaPeels

Interface for using MailChimp as a template repository for transactional emails. MailChimp campaigns define email content, using merge tags as placeholders for injectable content pieces.

## Installation

Add this line to your application's Gemfile:

    gem 'banana_peels'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install banana_peels

## Usage

### Campaign listing with ENV info (Rails)

app/controllers/campaigns_controller.rb:

```ruby
class CampaignsController < ApplicationController

  def index
    @campaigns = BananaPeels.campaigns(ENV['MAILCHIMP_API_KEY'])
    @env_vars = Hash.new{|h,k| h[k] = [] }
    by_id = @campaigns.index_by(&:id)
    ENV.each do |k,v|
      @env_vars[v].push(k) if by_id[v]
    end
  end

end

```

app/views/campaigns/index.html.slim (http://slim-lang.com/, similar to haml):
```slim
h1 MailChimp Campaigns
table
  thead
    tr
      th Campaign Title
      th MailChimp ID
      td
        strong ENV Keys
        |  | Merge Tags
  tbody
    - @campaigns.each do |c|
      tr
        th = c.title
        td = c.id
        td
          strong = @env_vars[c.id].join(', ')
          |  |
          = c.merge_tags_in_content.keys.join(', ')
      tr
        td rowspan="4"
        th Subject
        td = c.mailchimp_meta['subject']
      tr
        th From
        td = c.from
      tr
        th Text Content
        td = CGI.escapeHTML(c.text_content_unmerged).gsub("\n","\n<br>").html_safe
      tr
        th HTML Content
        td = c.html_content_unmerged
```

### Sending transactional emails using a MailChimp Campaign as a template

app/mailers/user_mailer.rb:
```ruby
class UserMailer < ActionMailer::Base
  include BananaPeels::MailerHelper

  def reset_password_instructions(record, token, opts={})
    user = User.find(record.id)
    mail_options = {
      to: BananaPeels.email_with_name("#{user.first_name} #{user.last_name}", user.email),
    }
    merge_tags = {
      'FIRST_NAME' => user.first_name,
      'LAST_NAME' => user.last_name,
      'RESET_PASSWORD_URL' => edit_user_password_url(reset_password_token: token),
    }
    banana_mail(ENV['RESET_PASSWORD_CAMPAIGN_ID'], mail_options, merge_tags, ENV['MAILCHIMP_API_KEY'])
  end

end
```

And then use the merge tags `*|FIRST_NAME|*`, `*|LAST_NAME|*`, `*|RESET_PASSWORD_URL|*` in your MailChimp Campaign.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
