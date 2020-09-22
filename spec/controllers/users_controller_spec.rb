require 'spec_helper'

describe UsersController do

  let!(:user) { create(:active_user) }
  let(:params) {
    {
      user: {
        firstname: user.firstname,
        lastname: user.lastname,
        username: user.username,
        email: user.email,
        password: 'password'
      },
      country: 'ie'
    }
  }
  let(:patch_params) {
    {
      id: user.username,
      "user-firstname" => 'Aaaddd',
      "user-lastname" => 'Bbbeeee',
      country: 'ie',
      email: user.email,
      password: 'asdf'
    }
  }
  let(:new_user_params) {
    id = SecureRandom.hex(8)
    {
      user: {
        firstname: 'Joe',
        lastname: 'Bloggs',
        username: id,
        email: "#{id}@nowhere.com",
        country: 'ie',
        password: 'password'
      },
    }
  }

  describe 'GET #new' do
    it "renders the :new" do
      get :new
      expect(response.status).to eq(200)
      expect(response).to render_template :new
    end
  end

  describe 'GET #confirm' do
    it "confirms user if parameters are correct" do
      code = Digest::SHA1.hexdigest(user.username + user.created_at.utc.to_s)
      get :confirm, params: {:u => user.username, :c => code}
      expect(response.status).to eq(302)
      expect(flash[:notice]).to eq('Successfully activated your account')
      expect(response).to redirect_to signin_path
    end

    it "fails to confirm if parameters are incorrect" do
      get :confirm, params: {:u => user.username, :c => '123'}
      expect(response.status).to eq(302)
      expect(flash[:notice]).to eq('Activation code is incorrect')
      expect(response).to redirect_to signin_path
    end
  end

  describe 'POST #create with wrong params' do
    it "renders the :new" do
      post :create, {}
      expect(response.status).to eq(200)
      expect(response).to render_template :new
    end
  end

  describe 'POST #create with correct params' do
    it "signs in and redirects to cameras index" do
      stub_request(:post, "#{EVERCAM_API}users.json").
        with(:body => { "email" => "#{CGI.escape(new_user_params[:user][:email])}", "firstname" => "Joe", "lastname" => "Bloggs", "password" => "password", "username" => "#{new_user_params[:user][:username]}" }).to_return(:status => 200, :body => '{"users": [{}]}', :headers => {})
      post :create, params: new_user_params
      expect(response.status).to eq(200)
    end
  end

  describe 'GET #settings' do
    it "redirects to signup" do
      get :settings, params: {id: 'tester'}
      expect(response).to redirect_to signin_path
    end
  end

  describe 'POST #settings' do
    it "redirects to signup" do
      post :settings_update, params: {id: 'tester'}
      expect(response).to redirect_to signin_path
    end
  end

  context 'with auth' do
    describe 'GET #settings' do
      it "renders the :settings" do
        stub_request(:patch, "#{EVERCAM_API}users/#{user.username}").
          to_return(:status => 200, :body => "", :headers => {})

        stub_request(:get, "#{EVERCAM_API}cameras.json?api_id=#{user.api_id}&api_key=#{user.api_key}&include_shared=true&thumbnail=false&user_id=#{user.username}").
          to_return(status: 200, headers: {}, body: "{\"cameras\": []}")

        session['user'] = user.email
        get :settings, params: {id: user.username}
        expect(response.status).to eq(200)
      end
    end

    describe 'POST #settings_update with wrong params' do
      it "fails and renders user settings" do
        stub_request(:patch, "#{EVERCAM_API}users/#{user.username}.json").
          with(:body => "api_id=#{user.api_id}&api_key=#{user.api_key}&firstname=",).
          to_return(:status => 400, :body => '{"message": ["firstname cannot be blank"]}', :headers => {})

        session['user'] = user.email
        post :settings_update, params: {id: user.username, 'user-firstname' => ''}
        expect(response.status).to eq(302)
        expect(response).to redirect_to user_settings_path
        expect(flash[:message]).to eq("An error occurred updating your details. Please try again and, if the problem persists, contact support.")
      end
    end

    describe 'POST #settings_update with correct params, but for different user' do
      it "signs out and redirects to sign in" do
        session['user'] = params[:user][:email]
        post :settings_update, params: {id: 'tester'}
        expect(response.status).to eq(302)
      end
    end

    describe 'POST #settings_update with correct params' do
      it "updates and renders user settings" do
        stub_request(:patch, "#{EVERCAM_API}users/#{user.username}.json").
          with(:body => {"api_id"=>user.api_id, "api_key"=>user.api_key, "user-firstname"=>"Aaaddd", "user-lastname"=>"Bbbeeee", "email"=>patch_params[:email], "country"=>"ie"}).
               to_return(:status => 200, :body => '{"users": [{}]}', :headers => {})

        session['user'] = user.email
        post :settings_update, params: patch_params
        expect(response.status).to eq(302)
      end
    end
  end

  context 'Password reset' do

    describe 'GET #password_reset_request' do
      it "renders the :password_reset_request" do
        get :password_reset_request
        expect(response.status).to eq(200)
        expect(response).to render_template :password_reset_request
      end
    end

    describe 'POST #password_reset_request with invalid params' do
      it "renders the :password_reset_request with error msg" do
        post :password_reset_request, params: {email: 'invalid'}
        expect(response.status).to eq(200)
        expect(response).to render_template :password_reset_request
        expect(flash[:message]).to eq('Email address not found.')
      end
    end

    describe 'POST #password_reset_request with valid params' do
      it "renders the :password_reset_request and creates reset_token" do
        post :password_reset_request, params: {email: user.email}
        expect(response.status).to eq(200)
        expect(response).to render_template :password_reset_request
        expect(flash[:message]).to eq('We’ve sent you an email with instructions for changing your password.')
        db_user = User.first
        new_token = db_user.reset_token
        expect(db_user.reset_token).to_not be_nil
        expect(db_user.token_expires_at).to be_within(1).of(Time.now + 24.hour)
        # Don't reset token when requested again
        post :password_reset_request, params: {email: user.email}
        expect(response.status).to eq(200)
        expect(response).to render_template :password_reset_request
        expect(flash[:message]).to eq('We’ve sent you an email with instructions for changing your password.')
        db_user = User.first
        expect(db_user.reset_token).to eq(new_token)
        expect(db_user.token_expires_at).to be_within(1).of(Time.now + 24.hour)
      end
    end

    describe 'GET #password_update_form' do
      it "renders the :password_reset_request" do
        get :password_update_form
        expect(response.status).to eq(200)
        expect(response).to render_template :password_update
      end
    end

    describe 'POST #password_update with invalid params' do
      it "renders the :password_update" do
        post :password_update
        expect(response.status).to eq(200)
        expect(response).to render_template :password_update
      end
    end

    describe 'POST #password_update with valid params' do
      it "updates password and redirects to index" do
        post :password_reset_request, params: {email: user.email}
        db_user = User.first
        post :password_update, params: {token: db_user.reset_token, username: db_user.email, password: 'test'}
        expect(response.status).to eq(302)
        expect(response).to redirect_to cameras_index_path
        db_user.reload
        expect(db_user.password).to eq('test')
      end
    end
  end
end
