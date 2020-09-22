FactoryBot.define do
   factory :camera do
      to_create {|instance| instance.save}

      created_at { Time.now - 86400 }
      updated_at { Time.now - 86400 }
      sequence(:exid) {|n| "camera-#{n}"}
      sequence(:name) {|n| "Camera #{n}"}
      association :owner, factory: :active_user
      config { "{}" }

      factory :public_camera do
         is_public { true }
      end

      factory :private_camera do
         is_public { false }
      end
   end
end
