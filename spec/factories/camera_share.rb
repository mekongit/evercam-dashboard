FactoryBot.define do
   factory :camera_share do
      to_create {|instance| instance.save}

      created_at { Time.now - 86400 }
      updated_at { Time.now - 86400 }
      association :user, factory: :active_user
      association :sharer, factory: :active_user

      factory :public_share do
         association :camera, factory: :public_camera
         kind { "public" }
      end

      factory :private_share do
         association :camera, factory: :private_camera
         kind { "private" }
      end
   end
end
