module BananaPeels::MailerHelper

  # Do "include BananaPeels::MailerHelper in an ActionMailer.

  def banana_mail(campaign_id, mail_options, merge_tags, api_key)
    BananaPeels.mail(self, campaign_id, mail_options, merge_tags, api_key)
  end

end
