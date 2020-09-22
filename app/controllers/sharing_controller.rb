class SharingController < ApplicationController
  before_action :authenticate_user!

  include SessionsHelper
  include ApplicationHelper

  def update_camera
    result = {success: true}
    if params[:id] && !params[:public].nil? && !params[:discoverable].nil?
      begin
        values = {
          id: params[:id],
          is_public: params[:public],
          discoverable: (params[:discoverable] == "true")
        }
        api = get_evercam_api
        api.update_camera(params[:id], values)
      rescue => error
        Rails.logger.warn "Exception caught updating camera permissions.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
        result[:success] = false
        result[:message] = "Failed to update camera permissions."
      end
    else
      result = {success: false, message: "Insufficient parameters provided."}
    end

    render json: result
  end

  def delete
    result = {success: true}
    if params[:camera_id] && params[:email]
      begin
        get_evercam_api.delete_camera_share(params[:camera_id], params[:email])
      rescue => error
        Rails.logger.warn "Exception caught deleting camera share.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
        result[:success] = false
        result[:message] = "Failed to delete camera share."
      end
    else
      result = {success: false, message: "Insufficient parameters provided."}
    end
    render json: result
  end

  def cancel_share_request
    result = {success: true}
    if params[:camera_id] && params[:email]
      begin
        get_evercam_api.cancel_camera_share_request(params[:camera_id], params[:email])
      rescue => error
        Rails.logger.warn "Exception caught cancelling camera share request.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
        result[:success] = false
        result[:message] = "Failed to delete camera share request."
      end
    else
      result = {success: false, message: "Insufficient parameters provided."}
    end
    render json: result
  end

  def resend_share_request
    result = {success: true}
    begin
      api = get_evercam_api
      camera_id = params[:camera_id]
      user = User.where(Sequel.ilike(:username, params[:user_name])).first
      @camera = api.get_camera(camera_id, true)
      UserMailer.sign_up_to_share_email(params[:email], "#{@camera["name"]}(#{camera_id})", user, params[:share_request_id], @camera['thumbnail']).deliver_now
    rescue => error
      Rails.logger.warn "Exception caught resending camera share request.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
      result[:success] = false
      result[:message] = "Failed to resend camera share request."
    end
    render json: result
  end

  def map_share_values(shares, type)
    shares.map do |share|
      {
        camera_id: share["camera_id"],
        share_id: share["id"],
        fullname: share["fullname"],
        email: share["email"],
        sharer_name: share["sharer_name"],
        sharer_email: share["sharer_email"],
        avatar: avatar_url(share["email"]),
        type: type,
        permissions: params[:permissions],
        user_id: share["user_id"],
      }
    end
  end

  def update_share
    result = {success: true}
    if params.include?(:camera_id) && params.include?(:email) && params.include?(:permissions)
      rights = generate_rights_list(params[:permissions])
      begin
        get_evercam_api.update_camera_share(params[:camera_id], params[:email], rights)
      rescue => error
        Rails.logger.warn "Exception caught updating camera share.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
        result = {success: false, message: "Failed to update share. Please contact support."}
      end
    else
      result = {success: false, message: "Insufficient parameters provided."}
    end
    render json: result
  end

  def update_share_request
    result = {success: true}
    if params.include?(:camera_id) && params.include?(:email) && params.include?(:permissions)
      rights = [AccessRight::LIST, AccessRight::SNAPSHOT]
      rights.concat([AccessRight::VIEW, AccessRight::EDIT, AccessRight::DELETE]) if params[:permissions] == "full"
      begin
        get_evercam_api.update_camera_share_request(params[:camera_id], params[:email], rights)
      rescue => error
        Rails.logger.warn "Exception caught updating camera share.\n"\
                              "Cause: #{error}\n" + error.backtrace.join("\n")
        result = {success: false, message: "Failed to update share request. Please contact support."}
      end
    else
      result = {success: false, message: "Insufficient parameters provided."}
    end
    render json: result
  end

  private

  def generate_rights_list(permissions)
    rights = [AccessRight::LIST, AccessRight::SNAPSHOT]
    if permissions == "full"
      AccessRight::BASE_RIGHTS.each do |right|
        if right != AccessRight::DELETE
          rights << right if !rights.include?(right)
          rights << "#{AccessRight::GRANT}~#{right}"
        end
      end
    elsif permissions == "minimal+share"
      rights = [AccessRight::LIST, AccessRight::SNAPSHOT, AccessRight::SHARE]
    end
    rights
  end
end
