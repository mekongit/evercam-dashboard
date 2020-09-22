require 'spec_helper'

describe "session related test", :type => :feature, :js => true do

  let!(:user) {
    create(:active_user, :password => 'pass')
  }

  it "User sings in with correct password" do
    stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=true").
      to_return(:status => 200, :body => '{"cameras": []}', :headers => {})

    stub_request(:get, "#{EVERCAM_API}shares/users/#{user.username}?api_id=#{user.api_id}&api_key=#{user.api_key}").
      to_return(:status => 200, :body => "{}", :headers => {})

    visit "/"
    fill_in "Email", :with => user.email
    fill_in "Password", :with => 'pass'
    click_button "Sign in"

    expect(page).to have_text("Cameras")
  end

  it "User signs in with incorrect password" do
    visit "/"
    fill_in "Email", :with => user.email
    fill_in "Password", :with => 'xxx'
    click_button "Sign in"

    expect(page.html.include?("Notification.show('Invalid login/password combination')")).to eq(true)
  end

end
