require 'spec_helper'
require_relative '../stub_helper'

describe "user actions", :type => :feature, :js => true do

  let!(:user) {
    create(:active_user, :password => 'pass')
  }

  it "User goes to his settings and updates them" do
    cameras_stubs(user)
    stub_request(:patch, "#{EVERCAM_API}users/#{user.username}.json").
      to_return(:status => 200, :body => '{}', :headers => {})

    page.set_rack_session(:user => user.email)

    visit "/"
    click_link user.fullname
    click_link 'Settings'

    expect(page).to have_text("User Settings")

    fill_in('user-firstname', :with => 'AAA')
    fill_in('user-lastname', :with => 'BBB')
    fill_in('email', :with => 'test@test.ie')

    click_button 'Save'

    # Check if there was request and if there was notification (there is no actual update)

    expect(page).to have_text("Settings updated successfully")

    expect(WebMock).to have_requested(:patch, "#{EVERCAM_API}users/#{user.username}.json").
       with(:body => {"api_id"=>"#{user.api_id}", "api_key"=>"#{user.api_key}", "country"=>"ie",
            "email"=>"test@test.ie", "firstname"=>"AAA", "lastname"=>"BBB"},
      :headers => {'Content-Type'=>'application/x-www-form-urlencoded'}).once

  end

  it "User goes to developer page" do
    cameras_stubs(user)
    page.set_rack_session(:user => user.email)
    visit "/"
    click_link 'Developer'

    expect(page).to have_text(user.api_id)
    expect(page).to have_text(user.api_key)

  end

  it "User sings up with correct data" do
    cameras_stubs(user)
    stub_request(:post, "#{EVERCAM_API}users.json").
      to_return(:status => 201, :body => '{"users":[{"username":"ccc"}]}', :headers => {})

    visit "/"
    click_link 'Create New Account'

    expect(page).to have_text('Create a free Account')

    fill_in('user_firstname', :with => 'AAA')
    fill_in('user_lastname', :with => 'BBB')
    fill_in('user_username', :with => 'ccc')
    fill_in('user_email', :with => 'ccc@aaa.ie')
    fill_in('user_password', :with => 'qwer')

    click_button 'Create New Account'

    expect(WebMock).to have_requested(:post, "#{EVERCAM_API}users.json").
      with(:body => 'country=ie&email=ccc%40aaa.ie&firstname=AAA&lastname=BBB&password=qwer&username=ccc',
      :headers => {'Content-Type'=>'application/x-www-form-urlencoded'}).once
  end

  it "User sings up with invalid data" do
    cameras_stubs(user)
    stub_request(:post, "#{EVERCAM_API}users.json").
      to_return(:status => 400, :body => '{
        "message": "Invalid parameters specified to request.",
        "code": "invalid_parameters",
        "context": [
          "email"
        ]
      }', :headers => {})

    visit "/"
    click_link 'Create New Account'

    expect(page).to have_text('Create a free Account')

    fill_in('user_firstname', :with => 'AAA')
    fill_in('user_lastname', :with => 'BBB')
    fill_in('user_username', :with => 'ccc')
    fill_in('user_email', :with => 'cccaaaie')
    fill_in('user_password', :with => 'qwer')

    click_button 'Create New Account'

    expect(WebMock).to have_requested(:post, "#{EVERCAM_API}users.json").
      with(:body => 'country=ie&email=cccaaaie&firstname=AAA&lastname=BBB&password=qwer&username=ccc',
      :headers => {'Content-Type'=>'application/x-www-form-urlencoded'}).once

    expect(page).to have_text('Must be a valid email address and at least 6 characters long.')
  end



end