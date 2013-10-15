class BananaPeels::Campaign

  class << self

    def replace_merge_tags(string, merge_tags)
      string.gsub(/\*\|(\w+)\|\*/) do
        merge_tags[$1.upcase]
      end
    end

  end

  # merge_tags: optional, nil for default
  def initialize(campaign_id, merge_tags, api_key)
    @campaign_id = campaign_id
    @merge_tags = normalize_merge_tags(merge_tags || {})
    @api = BananaPeels.api(api_key)
  end

  def mailchimp_meta
    # TODO: Cache campaigns from mailchimp.
    @mailchimp_meta ||= @api.campaigns.list({ campaign_id: @campaign_id })['data'].first
  end

  def mailchimp_content
    # TODO: Cache.
    @mailchimp_content ||= @api.campaigns.content(@campaign_id, { view: 'raw' })
  end

  def default_mail_options
    {
      from: from,
      subject: subject,
    }
  end

  def from
    BananaPeels.email_with_name(from_name, from_email)
  end

  def from_name
    mailchimp_meta['from_name']
  end

  def from_email
    mailchimp_meta['from_email']
  end

  def subject
    replace_merge_tags(mailchimp_meta['subject'])
  end

  def to_name
    replace_merge_tags(mailchimp_meta['to_name'])
  end

  def text_content
    content = mailchimp_content['text'].to_s
    content = content.sub(/=*\s*Unsubscribe\s\*\|HTML:EMAIL\|\*.*\z/m,'') # Auto-replaced if deleted.
    content = content.sub(/=*\s*This\semail\swas\ssent\sto\s\*\|EMAIL\|\*.*\z/m,'') # When generated from HTML version.
    content = content.sub(/=*\s*[^\n]*\*\|UNSUB\|\*.*\z/m,'') # Original generation.
    replace_merge_tags(content)
  end

  def html_content
    content = mailchimp_content['html'].to_s
    content = content.sub(/(.*)<center>.*?canspamBarWrapper.*?<\/center>/m,'\1')
    merge_tags = @merge_tags.dup
    merge_tags.each do |k,v|
      merge_tags[k] = CGI.escapeHTML(v.to_s).gsub("\n","\n<br>")
    end
    replace_merge_tags(content, merge_tags)
  end

  def replace_merge_tags(string, merge_tags=nil)
    self.class.replace_merge_tags(string, merge_tags || @merge_tags)
  end

  def normalize_merge_tags(merge_tags)
    normalized = {}
    if merge_tags
      merge_tags.each do |k,v|
        normalized[k.to_s.upcase] = v
      end
    end
    normalized['FNAME'] ||= normalized['FIRST_NAME']
    normalized['LNAME'] ||= normalized['LAST_NAME']
    normalized
  end

end
