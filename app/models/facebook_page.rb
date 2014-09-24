class FacebookPage < ActiveRecord::Base
  require 'open-uri'
  
  validates :fb_id, presence: true,     numericality: true,   uniqueness: true
  validates :likes, numericality: true, allow_nil: true
  validates :name,  presence: true
  
  # Call to find Facebook Page
  def self.search_page(fb_id)
    new_fb_info = FacebookPage.api_search_page(fb_id)
    if !new_fb_info.blank?
      if fb_page = FacebookPage.find_by_fb_id(fb_id)
        fb_page.attributes = new_fb_info
      else
        new_logo_name = "logo_" + FacebookPage.new_logo_name + ".png"
        
        Dir.mkdir("public/page_logos") unless Dir.exist?("public/page_logos/")
        
        Dir.chdir("public/page_logos/") do
          logo = File.new(new_logo_name,  "wb")
          open(logo, "wb") do |file|
            file << open(new_fb_info[:logo]).read
          end
        end
        
        new_fb_info[:logo] = new_logo_name
        fb_page = FacebookPage.new(new_fb_info)
      end
      fb_page.save ? fb_page : nil
    else
      nil
    end
  end
  
  # Call to find feeds
  def search_feeds
    feeds = self.api_search_feeds(access_token)
  end
  
  # To retrieve the file
  def logo_path
    "/page_logos/" + self.logo.to_s
  end
  
  protected
  
  # Find new name for logo
  def self.new_logo_name
    logo_name = SecureRandom.hex(10)
    while !FacebookPage.find_by_logo(logo_name).blank?
      logo_name = SecureRandom.hex(10)
    end
    logo_name
  end
  
  # Search page on Facebook
  def self.api_search_page(fb_id)
    url = "http://graph.facebook.com/" + fb_id.to_s + "/?fields=global_brand_page_name,likes,link,website,name,username,description,cover,about,picture.type(large)"
    fb_info_req = ApiAdapter.api_caller(:get, url)

    if fb_info_req["response"] == 0 && fb_info_req["data"][:id].to_i == fb_id.to_i
      new_fb_info = {
        fb_id:        fb_id,
        name:         fb_info_req["data"][:name],
        logo:         fb_info_req["data"][:picture][:data][:url],
        description:  fb_info_req["data"][:description],
        likes:        fb_info_req["data"][:likes]
      }
    else
      nil
    end
  end

  # Get feeds of a specific page
  def api_search_feeds
    access_token = (Rails.application.secrets.facebook_app_id.to_s + "|" + Rails.application.secrets.facebook_app_secret.to_s)
    url = URI::encode("https://graph.facebook.com/" + self.fb_id.to_s + "/posts?limit=20&access_token="+ access_token.to_s)
    fb_feed_req = ApiAdapter.api_caller(:get, url)

    if fb_feed_req["response"] == 0 && !fb_feed_req["data"][:data].blank?
      fb_feeds = []
      
      fb_feed_req["data"][:data].each_with_index do |feed, index|
        if !feed[:message].blank? && !feed[:link].blank?
          fb_feed = {}
          fb_feed[:from] = {}
          fb_feed[:from][:name] = feed[:from][:name]
          
          if self.name != feed[:from][:name]
            fb_page = FacebookPage.find_by_fb_id(feed[:from][:id])
            picture = fb_page.blank? ? FacebookPage.api_search_picture(feed[:from][:id]) : fb_page.logo_path
            fb_feed[:from][:picture] = picture unless picture.blank?
          else
            fb_feed[:from][:picture] = self.logo_path
          end
          
          fb_feed[:message] = feed[:message]
          fb_feed[:created_at] = feed[:created_time]
          fb_feed[:content] = {}
          fb_feed[:content][:picture] = feed[:picture]
          fb_feed[:content][:link] = feed[:link]
          fb_feed[:content][:title] = feed[:title]
          fb_feed[:content][:caption] = feed[:caption]
          fb_feed[:content][:description] = feed[:description]
          fb_feeds << fb_feed
        end
      end
      
      fb_feeds
    else
      nil
    end
  end
  
  # To get picture of contributor on FacebookPage
  def self.api_search_picture(fb_id)
    url = "http://graph.facebook.com/" + fb_id.to_s + "/?fields=picture.type(large)"
    fb_picture_req = ApiAdapter.api_caller(:get, url)

    if fb_picture_req["response"] == 0 && !fb_picture_req["data"][:id].blank?
      fb_picture = fb_info_req["data"][:picture][:data][:url]
    else
      nil
    end
  end
  
end