class URL
  include MongoMapper::Document

  key :url_key, String, :required => true
  key :full_url, String, :required => true
  key :last_accessed, Time
  key :times_viewed, Integer, :default => 0
  
  # Tip for URL validation taken from http://mbleigh.com/2009/02/18/quick-tip-rails-url-validation.html
  validates_format_of :full_url, :with => URI::regexp(%w(http https))

  def self.find_or_create(new_url, forced = false)

    if forced
      url_key = new_url
    else
      url_key = Digest::MD5.hexdigest(new_url)
      url_key = url_key.to_i(16) # transform to base16 (hexa)
      url_key = url_key.to_s(36) # transform to base36 ([0..9-a..z])
    end

    begin
      # Check if the key exists, so we don't have to create the URL again.
      url = self.find_by_url_key(url_key)
      if url.nil?
        url = URL.new(:url_key => url_key, :full_url => new_url)
        url.save!
      end
      return { :short_url => url.short_url, :full_url => url.full_url }
    rescue MongoMapper::DocumentNotValid
      return { :error => "'url' parameter is invalid" }.to_json
    end
  end

  def short_url
    # Note that if running locally, 'Sinatra::Application.host' will return '0.0.0.0'.
    if Sinatra::Application.port == 80
      "http://#{Sinatra::Application.bind}/#{self.url_key}"
    else
      "http://#{Sinatra::Application.bind}:#{Sinatra::Application.port}/#{self.url_key}"
    end
  end

  # Check if url_key already exists
  def self.is_already_key?(url_key)
    return !self.find_by_url_key(url_key).nil?
  end
end
