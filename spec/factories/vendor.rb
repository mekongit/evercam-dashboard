FactoryBot.define do
  factory :vendor do
    to_create {|instance| instance.save}

    sequence(:exid) { |n| "exid#{n}" }
    known_macs { ['00:00:01', '00:00:0A'] }
    sequence(:name) { |n| "name#{n}" }
  end
end
