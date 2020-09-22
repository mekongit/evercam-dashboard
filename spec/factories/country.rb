FactoryBot.define do
   factory :country do
      to_create {|instance| instance.save}

      created_at { Time.now - 86400 }
      updated_at { Time.now - 86400 }

      factory :ireland do
         iso3166_a2 { "ie" }
         name { "Ireland" }
      end

      factory :poland do
         iso3166_a2 { "pl" }
         name { "Poland" }
      end
   end
end
