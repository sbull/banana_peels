module BananaPeels

  class << self

    def api(api_key)
      API.new(api_key)
    end

    def campaigns(api_key)
      meta_list = campaigns_list(api_key)
      campaigns = []
      meta_list.each do |c_meta|
        c = campaign(c_meta['id'], nil, api_key)
        c.mailchimp_meta = c_meta
        campaigns.push(c)
      end
      campaigns
    end

    def campaigns_list(api_key)
      api_data = api(api_key).campaigns.list([], 0, 1000) # TODO: presumes <= 1000 campaigns
      api_data['data']
    end

    def campaign(campaign_id, merge_tags, api_key)
      Campaign.new(campaign_id, merge_tags, api_key)
    end

    # Use this instead of #mail() in ActionMailer.
    # Also allows :from_name, :from_email to be specified independently
    # as mail_options as opposed to just :from.
    def mail(mailer, campaign_id, mail_options, merge_tags, api_key)
      c = campaign(campaign_id, merge_tags, api_key)
      headers = c.default_mail_options.merge(mail_options)
      # Adjust from address.
      if !mail_options[:from] && (mail_options[:from_name] || mail_options[:from_email])
        headers[:from] = email_with_name(mail_options[:from_name] || c.from_name, mail_options[:from_email] || c.from_email)
      end
      mailer.mail(headers) do |format|
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


  class API

    attr_reader :api_key


    class << self

      def cache_get(key)
        cache[key]
      end

      def cache_set(key, value)
        cache[key] = value if cache?
        value
      end

      def cache?
        ['true', 't', 'yes', 'y', 'on'].include?(ENV['BANANA_PEELS_CACHE'].to_s.downcase)
      end


      private

      def cache
        @cache ||= {}
      end

    end


    def initialize(api_key)
      @api_key = api_key
    end

    def method_missing(method, *args)
      Proxy.new(@api_key, method)
    end


    class Proxy

      def initialize(api_key, mod)
        @api_key = api_key
        @mod = mod
      end

      def method_missing(method, *args)
        if API.cache?
          cache_keys = [ @api_key, @mod.to_s, method.to_s ]
          cache_keys.concat(args)
          cache_key = cache_keys.to_json
          cache_val = API.cache_get(cache_key)
          return cache_val if cache_val
        end
        cache_val = Mailchimp::API.new(@api_key).__send__(@mod).__send__(method, *args)
        API.cache_set(cache_key, cache_val) if API.cache?
        cache_val
      end

    end

  end


end
