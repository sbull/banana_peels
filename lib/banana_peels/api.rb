module BananaPeels

  class << self

    def api(api_key)
      Mailchimp::API.new(api_key)
    end

    def campaigns(api_key)
      api_data = api(api_key).campaigns.list([], 0, 1000) # TODO: presumes <= 1000 campaigns
      api_data['data']
    end

    def campaign(campaign_id, merge_tags, api_key)
      Campaign.new(campaign_id, merge_tags, api_key)
    end

    # Use this instead of #mail() in ActionMailer.
    def mail(mailer, campaign_id, mail_options, merge_tags, api_key)
      c = campaign(campaign_id, merge_tags, api_key)
      mailer.mail(c.default_mail_options.merge(mail_options)) do |format|
        format.text { mailer.render text: c.text_content }
        format.html(content_transfer_encoding: 'quoted-printable') do
          mailer.render text: [c.html_content].pack('M')
        end
      end
    end

    # Utility method.
    def email_with_name(name, email)
      name = name.gsub(/([\\"])/, '\\'=>'\\\\', '"'=>'\\"')
      "\"#{name}\" <#{email}>"
    end

  end

end
