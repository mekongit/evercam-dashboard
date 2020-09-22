FactoryBot.define do
   factory :camera_share_request do
      to_create {|instance| instance.save}

      association :camera, factory: :private_camera
      association :user, factory: :active_user
      key {SecureRandom.hex(25)}
      sequence(:email) {|n| "new.user#{n}@nowhere.com"}
      rights { "list,view" }

      factory :pending_camera_share_request do
         status { CameraShareRequest::PENDING }
      end

      factory :used_camera_share_request do
         status { CameraShareRequest::USED }
      end

      factory :cancelled_camera_share_request do
         status { CameraShareRequest::CANCELLED }
      end
   end
end

