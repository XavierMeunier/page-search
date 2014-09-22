require 'spec_helper'

describe FacebookPage do

  let(:facebook_page) { FactoryGirl.create(:random_facebook_page) }

  subject { facebook_page }
  
  it { should validate_uniqueness_of :fb_id }

  it { should validate_presence_of :fb_id }
  it { should validate_presence_of :name }

  it { should validate_numericality_of :fb_id }
  it { should validate_numericality_of :likes }
  
  
  it "should have the right attributes" do
    expect(facebook_page).to respond_to(:fb_id)
    expect(facebook_page).to respond_to(:name)
    expect(facebook_page).to respond_to(:logo)
    expect(facebook_page).to respond_to(:description)
    expect(facebook_page).to respond_to(:likes)
  end


  describe "new_logo_name" do
    let(:facebook_page_1) { FactoryGirl.create(:random_facebook_page, logo: FacebookPage.new_logo_name) }
    let(:facebook_page_2) { FactoryGirl.create(:random_facebook_page, logo: FacebookPage.new_logo_name) }
    let(:facebook_page_3) { FactoryGirl.create(:random_facebook_page, logo: FacebookPage.new_logo_name) }
    let(:facebook_page_4) { FactoryGirl.create(:random_facebook_page, logo: FacebookPage.new_logo_name) }

    context "no existing logo name" do
      it "should return a new valid logo name" do
        expect(FacebookPage.new_logo_name).to_not be_nil
      end
    end
    
    context "there is existing logo names" do
      it "should return unique logo name" do
        facebook_page_1
        facebook_page_2
        facebook_page_3
        facebook_page_4
        new_name = FacebookPage.new_logo_name
        expect(FacebookPage.find_by_logo(new_name)).to be_nil
      end
    end
    
  end
  
  describe "logo_path" do
    let(:facebook_page_1) { FactoryGirl.create(:random_facebook_page) }

    it "should return the full logo_path" do
      file_name = facebook_page_1.logo
      expect(facebook_page_1.logo_path).to eq(Rails.root.to_s + "/files/page_logo/" + file_name)
    end
  end
  
end