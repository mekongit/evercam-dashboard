FactoryBot.define do
  factory :vendor_model do
    to_create {|instance| instance.save}

    association :vendor, factory: :vendor
    sequence(:name) { |n| "name#{n}" }
    config { ({}) }
  end
end

