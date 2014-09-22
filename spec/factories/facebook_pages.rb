rand_numb = (0..7).map { (1..9).to_a.sample }.join

FactoryGirl.define do
  factory :facebook_page do
    
    trait :new_typical_facebook_page do
      fb_id         123456789
      name          "Page1"
      logo          "logo_123456789.png"
      description   "the long description is the best test"
      likes         123456
    end
    
    trait :new_random_facebook_page do      
      sequence(:fb_id)        {|n| rand_numb.to_i + n.to_i }
      sequence(:name)         {|n| "Page#{rand_numb.to_i + n.to_i}" }
      sequence(:logo)         {|n| "logo_#{rand_numb.to_i + n.to_i}" }
      sequence(:description)  {|n| "This is a very long description of #{rand_numb.to_i + n.to_i} letters." }
      sequence(:likes)        {|n| rand_numb.to_i + n.to_i }
    end
    
  factory :typical_facebook_page, traits: [:new_typical_facebook_page]
  factory :random_facebook_page, traits: [:new_random_facebook_page]
    
  end
end
