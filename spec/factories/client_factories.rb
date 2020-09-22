FactoryBot.define do
  factory :client do
    to_create {|instance| instance.save}

    sequence(:name) { |n| "client#{n}" }
    callback_uris { ['http://127.0.0.1'] }
    sequence(:api_id) {|n| SecureRandom.hex(10)}
    sequence(:api_key) {|n| SecureRandom.hex(16)}
  end
end

