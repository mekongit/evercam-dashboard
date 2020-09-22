class UsersController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:new, :create, :confirm,
                     :password_reset_request, :password_update, :password_update_form]
  layout "bare-bones", except: [:settings, :delete]
  include SessionsHelper
  include ApplicationHelper
  require "date"

  def new
    if params[:key] && current_user
      sign_out
    end
    unless current_user.nil?
      single_camera_redirection(cameras_index_path)
    end
    @share_request = nil
    get_referral_url()

    if params[:key]
      @share_request = CameraShareRequest.where(
        key: params[:key]
      ).first
      session[:referral_url] = "#{@share_request.user.email} shared #{@share_request.camera.name}"
      unless @share_request.nil?
        user = User.where(Sequel.ilike(:email, @share_request.email)).first
        unless user.blank?
          flash[:error] = "This signup link has already been used by #{@share_request.email.downcase}, You should either login to your existing account or create a new account."
          redirect_to signin_path
        end
      end
    end
  end

  def create
    user = params[:user]
    begin
      if user.nil?
        raise "No user details specified in request."
      end
      if request.safe_location && Evercam::Config.env == :production
        params[:country] = request.safe_location.country_code.downcase
      end

      get_evercam_api.create_user(
        user['firstname'],
        user['lastname'],
        "",
        user['email'],
        user['password'],
        ENV['WEB_APP_TOKEN'],
        params[:country],
        params[:key],
        session[:referral_url]
      )

      user = User.where(Sequel.ilike(:email, user[:email])).first
      sign_in user
      session[:referral_url] = nil
      update_user_intercom user
      single_camera_redirection(cameras_index_path)
    rescue => error
      if error.kind_of?(Evercam::EvercamError)
        if error.message.eql?("Invalid token.")
          flash[:message] = error.message
        else
          response = instance_eval{(error.message).first}
          if error.try(:status_code).present? && error.status_code.equal?(400)
            assess_field_errors(response)
          else
            flash[:message] = response.last.first
          end
        end
      else
        flash[:message] = "An error occurred creating your account. Please check "\
                            "the details and try again. If the problem persists, "\
                            "contact support."
      end
      Rails.logger.error "Exception caught in create user request.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      render action: "new", user: user
    end
  end

  def confirm
    user = User.by_login(params[:u])
    unless user.nil?
      code = Digest::SHA1.hexdigest(user.username + user.created_at.utc.to_s)
      if params[:c] == code
        user.confirmed_at = Time.now
        user.save
        flash[:notice] = 'Successfully activated your account'
      else
        flash[:notice] = 'Activation code is incorrect'
      end
    end
    redirect_to signin_path
  end

  def settings
    @cameras = load_user_cameras(true, false)
    @countries = Country.all
    @countries.sort_by! { |e| e.name.downcase }
    render layout: "user-account"
  end

  def delete
    begin
      get_evercam_api.delete_user(current_user.email)
      redirect_to good_bye_path
    rescue => error
      Rails.logger.error "Exception caught deleting user.\nCause: #{error}\n" +
                           error.backtrace.join("\n")
      flash[:message] = "An error occurred deleting user. Please try again "\
                      "and, if the problem persists, contact support."
      redirect_to user_settings_path
    end
  end

  def settings_update
    begin
      user_email = current_user.email
      parameters = {}
      parameters[:firstname] = params['user-firstname'] if params.include?('user-firstname')
      parameters[:lastname] = params['user-lastname'] if params.include?('user-lastname')
      parameters[:telegram_username] = params['telegram-username'] if params.include?('telegram-username')
      parameters[:country] = params['country'] if params.include?('country')
      if params.include?('email')
        unless params['email'] == current_user.email
          parameters[:email] = params['email']
          parameters[:username] = params['email']
          user_email = params['email']
        end
      end
      if !parameters.empty?
        old_email = current_user.email
        get_evercam_api.update_user(current_user.username, parameters)
        session[:user] = User.by_login(user_email).email
        update_user_intercom(current_user, old_email)
        refresh_user
      end

      if old_email != current_user.email && send_confirmation_email
        flash[:message] = 'Settings updated successfully and we’ve sent you a confirmation email with instructions.'
      else
        flash[:message] = 'Settings updated successfully'
      end
    rescue => error
      Rails.logger.error "Exception caught in update user request.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      if error.kind_of?(Evercam::EvercamError)
        response = instance_eval{(error.message).first}
        if response[1] && response[1][0]
          flash[:message] = response[1][0]
        else
          flash[:message] = "An error occurred updating your details. Please try "\
          "again and, if the problem persists, contact support."
        end
      else
        flash[:message] = "An error occurred updating your details. Please try "\
                        "again and, if the problem persists, contact support."
      end
    end
    redirect_to user_settings_path
  end

  def change_password
    begin
      user = User.by_login(current_user.email)
    rescue NoMethodError => error
      Rails.logger.error "Error caught fetching user details.\nCause: #{error}\n" + error.backtrace.join("\n")
    end

    if !user.nil? and user.password == params['current-password']
      user.update(password: params['new-password'])
      user.save
      flash[:message] = 'Password updated successfully'
    else
      flash[:message] = 'Invalid Current Password'
    end
    redirect_to user_settings_path
  end

  def password_reset_request
    get_referral_url()
    email = params[:email].downcase if params[:email]
    unless email.nil?
      user = User.by_login(email)

      if user
        t = Time.now
        if user.reset_token.present? and user.token_expires_at.present? and user.token_expires_at > t
          expires = user.token_expires_at
          token = user.reset_token
        else
          expires = t + 24.hour
          token = SecureRandom.hex(16)
        end

        user.update(reset_token: token, token_expires_at: expires)

        UserMailer.password_reset(email, user, token).deliver_now
        flash.now[:message] = "We’ve sent you an email with instructions for changing your password."
      else
        flash.now[:message] = "Email address not found."
      end
    end
  end

  def password_update_form
    username = params[:u]
    user = User.by_login(username)
    if user.nil? or user.token_expires_at.blank? or user.token_expires_at < Time.now
      @expired = true
    else
      @expired = false
    end
    render "password_update"
  end

  def password_update
    token = params[:token]
    username = params[:username]
    user = User.by_login(username)
    if user.nil? or token != user.reset_token or user.token_expires_at < Time.now
      flash[:message] = 'Invalid username or token'
    else
      user.update(reset_token: '', token_expires_at: Time.now)
      user.password = params[:password]
      user.save
      sign_in user
      redirect_to cameras_index_path, message: 'Your password has been changed'
    end
  end

  def resend_confirmation_email
    result = send_confirmation_email
    unless result
      flash[:message] = 'We’ve sent you a confirmation email with instructions.'
    else
      flash[:message] = t("errors.user_not_found_error")
    end
    redirect_to user_settings_path
  end

  private

  def send_confirmation_email
    user = User.where(Sequel.ilike(:email, current_user.email)).first
    unless user.nil?
      code = Digest::SHA1.hexdigest(user.username + user.created_at.utc.to_s)
      UserMailer.resend_confirmation_email(user, code).deliver_now
      true
    else
      false
    end
  end

  def assess_field_errors(error)
    field_errors = {}
    field_errors[error.first] = error.last.first
    flash[:field_errors] = field_errors
  end
end
