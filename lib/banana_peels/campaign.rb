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
  def mailchimp_meta=(mailchimp_meta)
    @mailchimp_meta = mailchimp_meta
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

  def id
    mailchimp_meta['id']
  end

  def title
    mailchimp_meta['title']
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

  def merge_tags_in_content
    merge_tags = Hash.new{|h,k| h[k] = [] }
    {
      to: mailchimp_meta['to_name'],
      subject: mailchimp_meta['subject'],
      html: html_content_unmerged,
      text: text_content_unmerged,
    }.each do |location, content|
      find_merge_tags_in(content).each do |tag|
        merge_tags[tag].push(location)
      end
    end
    merge_tags
  end

  def find_merge_tags_in(string)
    string.scan(/\*\|(\w+)\|\*/).flatten.uniq
  end

  def text_content_unmerged
    content = mailchimp_content['text'].to_s
    content = content.sub(/=*\s*Unsubscribe\s\*\|HTML:EMAIL\|\*.*\z/m,'') # Auto-replaced if deleted.
    content = content.sub(/=*\s*This\semail\swas\ssent\sto\s\*\|EMAIL\|\*.*\z/m,'') # When generated from HTML version.
    content = content.sub(/=*\s*[^\n]*\*\|UNSUB\|\*.*\z/m,'') # Original generation.
    content
  end

  def text_content
    replace_merge_tags(text_content_unmerged)
  end

  def html_content_unmerged
    content = mailchimp_content['html'].to_s
    content = content.sub(/(.*)<center>.*?canspamBarWrapper.*?<\/center>/m,'\1')
    content
  end

  def html_content
    merge_tags = @merge_tags.dup
    merge_tags.each do |k,v|
      merge_tags[k] = CGI.escapeHTML(v.to_s).gsub("\n","\n<br>")
    end
    replace_merge_tags(html_content_unmerged, merge_tags)
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
