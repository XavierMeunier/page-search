class CreateFacebookPage < ActiveRecord::Migration
  def change
    create_table :facebook_pages do |t|
      t.integer :fb_id, :limit => 8
      t.string  :name
      t.string  :logo
      t.text    :description
      t.integer :likes
      t.timestamps
    end
  end
end