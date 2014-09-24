class FacebookPagesController < ApplicationController

  def index
    @fb_page = FacebookPage.find_by_fb_id(params[:fb_id]) if params[:fb_id]
    @fb_pages = FacebookPage.all.sort { |a,b| a.updated_at <=> b.updated_at }.reverse.take(5) unless FacebookPage.all.blank?
    
    respond_to do |format|
      format.html
      format.json { render json: @fb_pages }
    end
  end
  
  def show
    @fb_page = FacebookPage.find(params[:id])
    if @fb_page
      @feeds = @fb_page.search_feeds(params[:access_token])
      if @feeds
        respond_to do |format|
          format.html
          format.json { render json: @feeds }
        end
      else
        redirect_to root_path, alert: "No Facebook feeds found."
      end
    else
      redirect_to root_path, alert: "No Facebook page found."
    end
  end

  def page_search
    @fb_page = FacebookPage.find_by_fb_id(params[:fb_id])
    @fb_page = FacebookPage.search_page(params[:fb_id]) if @fb_page.blank?
    
    if @fb_page.is_a?(FacebookPage)
      @fb_page.update_attributes(updated_at: Time.now)
      redirect_to index_path(@fb_page.fb_id)
    else
      redirect_to root_path, alert: "No Facebook page found."
    end
  end

end