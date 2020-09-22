FactoryBot.define do
  factory :access_token do
    to_create {|instance| instance.save}

    association :user, factory: :user
    association :client, factory: :client
    association :grantor, factory: :user
  end
end

