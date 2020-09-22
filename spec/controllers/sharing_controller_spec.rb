require 'spec_helper'

describe SharingController do
   describe 'POST /share/camera/:id' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:other_camera) {
         create(:private_camera)
      }

      let(:owner) {
         camera.owner
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:discoverable => false,
          :id =>           camera.exid,
          :public =>       false}
      }

      it "returns success for a valid request" do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}").
            to_return(:status => 200, :body => "", :headers => {})

         post :update_camera, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it "returns failure for an non-existent camera" do
         stub_request(:patch, "#{EVERCAM_API}cameras/blah.json").
            to_return(:status => 404, :body => "", :headers => {})

         parameters[:id]  = "blah"
         post :update_camera, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it "returns failure for a camera that is owned by someone else" do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{other_camera.exid}.json").
            to_return(:status => 403, :body => "", :headers => {})

         parameters[:id]  = other_camera.exid
         post :update_camera, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it "returns failure if a public parameter is not specified" do
         parameters.delete(:public)
         post :update_camera, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it "returns failure if a discoverable parameter is not specified" do
         parameters.delete(:discoverable)
         post :update_camera, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end
   end

   #----------------------------------------------------------------------------

   describe 'DELETE /share' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:share) {
         create(:private_share, camera: camera, user: camera.owner)
      }

      let(:owner) {
         camera.owner
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:camera_id => camera.exid,
          :share_id => share.id}
      }

      it 'returns failure if a camera_id is not specified' do
         parameters.delete(:camera_id)
         delete :delete, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns failure if a share_id is not specified' do
         parameters.delete(:share_id)
         delete :delete, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}/shares.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}").
            to_return(:status => 403, :body => "", :headers => {})

         delete :delete, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}cameras/#{camera.exid}/shares.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}").
            to_return(:status => 200, :body => "", :headers => {})

         delete :delete, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end
   end

   #----------------------------------------------------------------------------

   describe 'POST /share' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:share) {
         create(:private_share, camera: camera, user: camera.owner)
      }

      let!(:owner) {
         camera.owner
      }

      let!(:shared_with) {
         create(:active_user)
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:camera_id => camera.exid,
          :permissions => "full",
          :email => shared_with.email}
      }

      it 'returns failure if an email address is not specified' do
         parameters.delete(:email)
         post :update_share, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns failure if a permissions setting is not specified' do
         parameters.delete(:permissions)
         post :update_share, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end
   end

   #----------------------------------------------------------------------------

   describe 'PATCH /share' do
      let!(:share) {
         create(:private_share)
      }

      let(:camera) {
         share.camera
      }

      let(:owner) {
         camera.owner
      }

      let(:parameters) {
         {id: share.id, permissions: "full"}
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{share.id}/shares.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 200, :body => "", :headers => {})

         patch :update_share, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{share.id}/shares.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 403, :body => '{"message": "Unauthorized"}', :headers => {})

         patch :update_share, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end

      it 'returns failure if permissions are not specified' do
         parameters.delete(:permissions)
         patch :update_share, params: {:id => parameters.merge(credentials), :user => owner.email}
         expect(response.status).to eq(302)
      end
   end
end
