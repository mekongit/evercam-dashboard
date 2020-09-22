namespace :intercom do
  desc 'update has_shared and has_snapmail for all intercom users'
  task :update_fields, [:DATABASE_URL, :app_id, :app_key, :user_id] do |_t, args|
    require 'intercom'
    ActiveRecord::Base.establish_connection("#{args[:DATABASE_URL]}")
    users = ActiveRecord::Base.connection.select_all("select * from users where id > #{args[:user_id]} order by id")

    intercom = Intercom::Client.new(
      app_id: args[:app_id],
      api_key: args[:app_key]
    )

    users.each do |user|
      begin
        ic_user = intercom.users.find(:user_id => user["username"])
      rescue Intercom::ResourceNotFound
        # Ignore it
      end
      unless ic_user.nil?
        has_shared = false
        has_snapmail = false
        if ActiveRecord::Base.connection.select_all("select * from camera_shares where sharer_id=#{user["id"]}").count > 0
          has_shared = true
        end
        if ActiveRecord::Base.connection.select_all("SELECT * FROM snapmails WHERE recipients like '%#{user["email"]}%'").count > 0
          has_snapmail = true
        end
        if has_shared || has_snapmail
          ic_user.custom_attributes = {"has_shared": has_shared, "has_snapmail": has_snapmail}
          intercom.users.save(ic_user)
          puts "Update user (#{user["id"]}): #{user["username"]}\t#{user["email"]}, has_shared=#{has_shared}, has_snapmail=#{has_snapmail}"
        else
          puts "Skip user (#{user["id"]}): #{user["username"]}\t#{user["email"]}"
        end
      end
    end
  end

  task :update_unknown_values, [:DATABASE_URL, :app_id, :app_key, :user_id] do |_t, args|
    require 'intercom'
    ActiveRecord::Base.establish_connection("#{args[:DATABASE_URL]}")
    users = ActiveRecord::Base.connection.select_all("select * from users where id > #{args[:user_id]} order by id")

    intercom = Intercom::Client.new(
        app_id: args[:app_id],
        api_key: args[:app_key]
    )

    users.each do |user|
      begin
        ic_user = intercom.users.find(:user_id => user["username"])
      rescue Intercom::ResourceNotFound
        # Ignore it
      end
      unless ic_user.nil?
        is_update = false

        if ic_user.custom_attributes["viewed_camera"].nil?
          is_update = true
          ic_user.custom_attributes["viewed_camera"] = 0
        end

        if ic_user.custom_attributes["viewed_recordings"].nil?
          is_update = true
          ic_user.custom_attributes["viewed_recordings"] = 0
        end

        if ic_user.custom_attributes["has_shared"].nil?
          is_update = true
          ic_user.custom_attributes["has_shared"] = false
        end

        if ic_user.custom_attributes["has_snapmail"].nil?
          is_update = true
          ic_user.custom_attributes["has_snapmail"] = false
        end

        if is_update
          intercom.users.save(ic_user)
          puts "Update user (#{user["id"]}): #{user["username"]}\t#{user["email"]}, viewed_camera=#{ic_user.custom_attributes["viewed_camera"]},"+
                   "viewed_recordings=#{ic_user.custom_attributes["viewed_recordings"]}, has_shared=#{ic_user.custom_attributes["has_shared"]},"+
                   "has_snapmail=#{ic_user.custom_attributes["has_snapmail"]}"
        end
      end
    end
  end

  task :add_companies, [:DATABASE_URL, :app_id, :app_key, :company_emails] do |_t, args|
    require 'intercom'
    ActiveRecord::Base.establish_connection("#{args[:DATABASE_URL]}")
    company_emails = args[:company_emails].split(" ").inject([]) { |list, entry| list << entry.strip }

    intercom = Intercom::Client.new(
        app_id: args[:app_id],
        api_key: args[:app_key]
    )

    company_emails.each do |company_email|
      puts "Start company #{company_email}"
      company = intercom.companies.find(:company_id => "#{company_email}")
      users = ActiveRecord::Base.connection.select_all("select * from users where email like '%@#{company_email}'")
      users.each do |user|
        begin
          ic_user = intercom.users.find(:user_id => user["username"])
        rescue Intercom::ResourceNotFound
          # Ignore it
        end
        unless ic_user.nil?
          ic_user.companies = [{company_id: "#{company.company_id}"}]
          intercom.users.save(ic_user)
          puts "Update user (#{user["id"]}): #{user["username"]}\t#{user["email"]}"
        end
      end
    end
  end

  task :sync_users_tag, [:DATABASE_URL, :app_id, :app_key, :tag_id] do |_t, args|
    require 'intercom'
    ActiveRecord::Base.establish_connection("#{args[:DATABASE_URL]}")
    intercom = Intercom::Client.new(
        app_id: args[:app_id],
        api_key: args[:app_key]
    )
    users = intercom.users.find(tag_id: args[:tag_id])
    puts "Total-Pages: #{users.pages.total_pages}"
    (1..users.pages.total_pages.to_i).each do |page|
      puts "Next Page: #{page}"
      unless page == 1
        users = intercom.users.find(tag_id: args[:tag_id], page: page)
        puts "Next Page Info:"
      end
      users.users.each do |ic_user|
        db_user = ActiveRecord::Base.connection.select_all("select * from users where email='#{ic_user["email"]}'")
        if db_user.present?
          ActiveRecord::Base.connection.select_all("update users set payment_method=2 where id=#{db_user[0]["id"]} and email='#{ic_user["email"]}'")
          puts "user #{db_user[0]["email"]} - #{db_user[0]["id"]}"
          puts "------------------------------------------------"
        end
      end
    end
    puts "Task finished"
  end
end
