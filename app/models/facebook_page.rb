class FacebookPage < ActiveRecord::Base
  require 'open-uri'
  
  validates :fb_id, presence: true,     numericality: true,   uniqueness: true
  validates :likes, numericality: true, allow_nil: true
  validates :name,  presence: true
  

  def self.search_page(fb_id)
    new_fb_info = FacebookPage.api_search_page(fb_id)

    if !new_fb_info.blank?
      if fb_page = FacebookPage.find_by_fb_id(fb_id)
        fb_page.attributes = new_fb_info
      else
        new_logo_name = "logo_" + FacebookPage.new_logo_name + ".png"
        open(new_logo_name, 'wb') do |file|
          file << open(new_fb_info[:logo]).read
        end
        new_fb_info[:logo] = new_logo_name
        fb_page = FacebookPage.new(new_fb_info)
      end
      fb_page.save ? fb_page : nil
    else
      nil
    end
  end
  
  def search_feeds
    feeds = self.api_search_feeds
  end
  
  def logo_path
    Rails.root.to_s + "/files/page_logo/" + self.logo.to_s
  end
  
  protected
  
  def self.new_logo_name
    logo_name = SecureRandom.hex(10)
    while !FacebookPage.find_by_logo(logo_name).blank?
      logo_name = SecureRandom.hex(10)
    end
    logo_name
  end
  
  def self.api_search_page(fb_id)
    url = "http://graph.facebook.com/" + fb_id.to_s + "/?fields=global_brand_page_name,likes,link,website,name,username,description,cover,about,photos.type(profile)"
    fb_info_req = ApiAdapter.api_caller(:get, url)

    if fb_info_req["response"] == 0 && fb_info_req["data"][:id].to_i == fb_id.to_i
      new_fb_info = {
        fb_id:        fb_id,
        name:         fb_info_req["data"][:name],
        logo:         fb_info_req["data"][:photos][:data][0][:picture],
        description:  fb_info_req["data"][:description],
        likes:        fb_info_req["data"][:likes]
      }
    else
      nil
    end
  end

  def api_search_feeds
    url = URI::encode("https://graph.facebook.com/" + self.fb_id.to_s + "/posts?limit=30&access_token="+ Rails.application.secrets.facebook_app_id.to_s + "|" + Rails.application.secrets.facebook_app_secret.to_s)
    fb_feed_req = ApiAdapter.api_caller(:get, url)

    if fb_feed_req["response"] == 0 && !fb_feed_req["data"][:data].blank?
      fb_feeds = {}
      
      fb_feed_req["data"][:data].each_with_index do |feed, index|
        fb_feeds[index] = {}
        fb_feeds[index][:from] = feed[:from][:name]
        fb_feeds[index][:message] = feed[:message]
        fb_feeds[index][:created_at] = feed[:created_time]
        fb_feeds[index][:content] = {}
        fb_feeds[index][:content][:picture] = feed[:picture]
        fb_feeds[index][:content][:link] = feed[:link]
        fb_feeds[index][:content][:title] = feed[:title]
        fb_feeds[index][:content][:caption] = feed[:caption]
        fb_feeds[index][:content][:description] = feed[:description]
      end
      
      fb_feeds
    else
      nil
    end
  end
  

  
end