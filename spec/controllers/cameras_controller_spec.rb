require 'spec_helper'

describe CamerasController do
  let!(:user) {
    create(:active_user)
  }

  let!(:camera) {
    create(:private_camera)
  }

  let!(:camera2) {
    create(:private_camera)
  }

  let(:params) {
    {'camera-id' => camera.exid,
     'id' => camera.exid,
     'camera-name' => 'My Cam',
     'camera-url' => '1.1.1.1',
     'snapshot' => '/jpg',
     'camera-username' => '',
     'camera-password' => '',
     'camera-vendor' => '',
     'camera-model' => '',
     'local-http' => '',
     'port' => '',
     'ext-rtsp-port' => '',
     'local-rtsp' => '',
     'local-ip' => '',
     'camera-lat' => '',
     'camera-lng' => ''}
  }

  let(:patch_params) {
    {'camera-id' => camera.exid,
     'id' => camera.exid,
     'camera-name' => 'My New Cam',
     'camera-url' => '1.1.1.2',
     'snapshot' => '/jpeg',
     'camera-username' => '',
     'camera-password' => '',
     'camera-vendor' => '',
     'local-http' => '',
     'ext-rtsp-port' => '',
     'port' => '',
     'local-rtsp' => '',
     'local-ip' => '',
     'camera-lat' => '',
     'camera-lng' => ''}
  }

  describe 'GET #index without auth' do
    it "redirects to signup" do
      get :index
      expect(response).to redirect_to signin_path
    end
  end

  describe 'GET #new without auth' do
    it "redirects to signup" do
      get :new
      expect(response).to redirect_to signin_path
    end
  end

  describe 'POST #new without auth' do
    it "redirects to signup" do
      post :new
      expect(response).to redirect_to signin_path
    end
  end

  context 'with auth' do
    describe 'GET #index' do
      it "renders the :index" do
        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=false&user_id=#{user.username}").
          to_return(status: 200, headers: {}, body: "{\"cameras\": []}")

        stub_request(:get, "#{EVERCAM_API}shares/users/#{user.username}?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => "{}", :headers => {})

        session['user'] = user.email
        get :index
        expect(response.status).to eq(302)
      end
    end

    describe 'GET #new' do
      it "renders the :new" do
        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=false&user_id=#{user.username}").
          to_return(status: 200, headers: {}, body: "{\"cameras\": []}")

        session['user'] = user.email
        get :new
        expect(response.status).to eq(200)
        expect(response).to render_template :new
      end
    end

    describe 'POST #create with valid parameters' do
      it "redirects to the newly created camera" do
        stub_request(:post, "#{EVERCAM_API}cameras").
          to_return(:status => 200, :body => '{"cameras": [{}]}', :headers => {})

        session['user'] = user.email
        post :create, params: params
        expect(response.status).to eq(302)
      end
    end

    let!(:model) {
      create(:vendor_model)
    }

    let(:full_params) {
      {'camera-id' => camera.exid,
       'camera-name' => 'My Cam',
       'camera-url' => '1.1.1.1',
       'snapshot' => '/jpg',
       'camera-username' => 'aaa',
       'camera-password' => 'xxx',
       'camera-vendor' => model.vendor.exid,
       "camera-model#{model.vendor.exid}" => model.name,
       'local-http' => '111',
       'ext-rtsp-port' => '333',
       'port' => '8888',
       'local-rtsp' => '222',
       'local-ip' => '127.0.1.1'}
    }

    describe 'POST #create with valid full parameters' do
      it "redirects to the newly created camera" do
        stub_request(:post, "#{EVERCAM_API}cameras.json").
          to_return(:status => 200, :body => '{"cameras": [{}]}', :headers => {})

        stub_request(:post, "#{EVERCAM_API}cameras/#{params['camera-id']}/recordings/snapshots.json").
          to_return(:status => 200, :body => '{"snapshots": [{"camera": "aaaa11123","notes": null,"created_at": 1401205738,"timezone": "Etc/UTC"}]}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=true").
          to_return(status: 200, headers: {}, body: "{\"cameras\": []}")

        session['user'] = user.email
        post :create, params: full_params
        expect(response.status).to eq(302)
      end
    end

    describe 'POST #create with valid full parameters, but snapshot error' do
      it "redirects to the newly created camera" do
        stub_request(:post, "#{EVERCAM_API}cameras.json").
          to_return(:status => 200, :body => '{"cameras": [{}]}', :headers => {})

        stub_request(:post, "#{EVERCAM_API}cameras/#{params['camera-id']}/recordings/snapshots.json").
          to_return(:status => 500, :body => '{"message":"error"', :headers => {})

        session['user'] = user.email
        post :create, params: full_params
        expect(response.status).to eq(302)
      end
    end

    describe 'POST #create with missing parameters' do
      it "redirects to the new camera form" do
        session['user'] = user.email
        post :create, {}
        expect(response.status).to eq(302)
        expect(response).to redirect_to cameras_new_path
      end
    end

    describe 'POST #update with valid parameters' do
      it "redirects to the updated camera" do
        stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}.json").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :update, params: patch_params
        expect(response).to be_successful
        camera.reload
        expect(camera.is_public?).to eq(false)
      end
    end

    describe 'PATCH #update with missing parameters' do
      it "renders camera settings form" do
        stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}.json").
          to_return(status: 400, headers: {},
                    body: "{\"message\": [\"name can't be blank\", \"jpg url can't be blank\", \"external host can't be blank\"]}")
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
         to_return(:status => 200, :body => "{\"cameras\": [{}]}", :headers => {})

        stub_request(:get, "#{EVERCAM_API}users/#{user.username}/cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})

        session['user'] = user.email
        patch :update, params: {'id' => camera.exid, 'camera-id' => camera.exid}
        expect(response.status).to eq(200)
      end
    end

    describe 'GET #single' do
      it "renders the :single" do
        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}&include_shared=true&thumbnail=false&user_id=#{camera.owner.username}").
          to_return(status: 200, headers: {}, body: "{\"cameras\": []}")
        stub_request(:get, "#{EVERCAM_API}cameras/#{params['camera-id']}.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}&thumbnail=true").
          to_return(status: 200, headers: {}, body: '{"cameras": [{"owner":"'+camera.owner.username+'"}]}')
        stub_request(:get, "#{EVERCAM_API}cameras/#{params['camera-id']}/shares.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}").
          to_return(:status => 200, :body => "{\"shares\": []}", :headers => {})
        stub_request(:get, "#{EVERCAM_API}users/#{camera.owner.username}/cameras.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}&include_shared=true&thumbnail=true").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{params['camera-id']}/shares/requests.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}&status=PENDING").
          to_return(:status => 200, :body => '{"share_requests": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{params['camera-id']}/shares/requests.json?api_id=#{camera.owner.api_id}&api_key=#{camera.owner.api_key}").
           to_return(:status => 200, :body => '{"shares": []}', :headers => {})

        session['user'] = camera.owner.email
        get :single, params: {'id' => camera.exid}
        expect(response.status).to eq(302)
      end
    end

    describe 'GET #single we dont have rights to' do
      it "redirects to cameras index" do
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera2.exid}.json?api_id=#{user.api_id}&api_key=#{user.api_key}&thumbnail=true").
          to_return(status: 200, headers: {}, body: "{\"cameras\": [{}]}")
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera2.exid}/shares.json?api_id=#{user.api_id}&api_key=#{user.api_key}&user_id=#{user.username}").
          to_return(:status => 200, :body => "{\"shares\": []}", :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=true&user_id=#{user.username}").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera2.exid}/shares/requests.json?api_id=#{user.api_id}&api_key=#{user.api_key}&status=PENDING").
          to_return(:status => 200, :body => '{"share_requests": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera2.exid}/shares/requests.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
           to_return(:status => 200, :body => '{"shares": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera2.exid}/logs.json?api_id=#{user.api_id}&api_key=#{user.api_key}&objects=true&page=-1&types=").
          to_return(:status => 200, :body => '{"logs": [{}], "pages": 1}', :headers => {})

        session['user'] = user.email
        get :single, params: { id: camera2.exid }
        expect(response.status).to eq(302)
      end
    end

    describe 'POST #delete with valid parameters' do
      it "deletes the camera redirects to index" do
        stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => "", :headers => {})

        session['user'] = user.email
        post :delete, params: {'id' => params['camera-id']}
        expect(response.status).to eq(200)
      end
    end

    describe 'POST #delete with invalid parameters' do
      it "redirects to the index page" do
        stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"message": "failed"}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"cameras": [{}]}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}shares.json?api_id=#{user.api_id}&api_key=#{user.api_key}&camera_id=#{camera.exid}&user_id=#{user.username}").
          to_return(:status => 200, :body => '{"shares": [{}]}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}/shares.json?api_id=#{user.api_id}&api_key=#{user.api_key}").
          to_return(:status => 200, :body => '{"shares": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}/shares/requests.json?api_id=#{user.api_id}&api_key=#{user.api_key}&status=PENDING").
          to_return(:status => 200, :body => '{"share_requests": []}', :headers => {})
        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=false&user_id=#{user.username}").
          to_return(:status => 200, :body => '{"cameras": []}', :headers => {})

        session['user'] = user.email
        post :delete, params: {'id' => params['camera-id']}
        expect(response.status).to eq(200)
      end
    end
  end
end
