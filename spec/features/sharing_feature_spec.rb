require 'spec_helper'
require 'json'
require_relative '../stub_helper'

describe "sharing actions", :type => :feature, :js => true do

  let!(:user) {
    create(:active_user, :password => 'pass')
  }

  let!(:user2) {
    create(:active_user, :password => 'pass')
  }

  it "User shares his camera" do
    cameras_stubs(user)
    stub_request(:post, "#{EVERCAM_API}shares/cameras/testcam.json").
      to_return(:status => 200, :body => '{
        "share_requests": [
          {
            "id": "9433a3970ec9799d277b92187d95e9d70f6a653c810f1df801",
            "camera_id": "austin2",
            "user_id": "tjama",
            "email": "teast@aa.pl",
            "rights": "View"
          }
        ]
      }', :headers => {})

    stub_request(:get, "#{EVERCAM_API}cameras/testcam/snapshot.jpg?api_id=#{user.api_id}&api_key=#{user.api_key}").
      to_return(:status => 200, :body => '"data":"aaa"', :headers => {})

    page.set_rack_session(:user => user.email)
    visit "/"
    first(:link, 'Test Camera').click
    click_link 'Sharing'

    fill_in('sharingUserEmail', :with => user2.email)

    click_button 'submit_share_button'

    expect(page).to have_text("A notification email has been sent to the specified email address.")
    expect(WebMock).to have_requested(:post, "#{EVERCAM_API}shares/cameras/testcam.json").
      with(:body => {:api_id =>"#{user.api_id}", :api_key =>"#{user.api_key}",
                    :email=>user2.email, :rights=>"list,snapshot"}).once
  end

end