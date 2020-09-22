class SessionsController < ApplicationController
  include SessionsHelper
  include ApplicationHelper

  skip_before_action :authenticate_user!
  protect_from_forgery except: :destroy
  after_action :allow_iframe, only: [:widget_new, :live_view_private_widget, :hikvision_private_widget, :snapshot_navigator_widget]
  layout "bare-bones"

  def new
    if current_user.nil?
      if params["url"]
        session[:referral_url] = params["url"]
      else
        get_referral_url()
      end
      @remote_auth = is_remote_auth_req
    else
      if is_remote_auth_req
        create_to_zoho_and_login(current_user)
      else
        redirect_to cameras_index_path
      end
    end
  end

  def widget_new
    redirect_to cameras_index_path unless current_user.nil?
  end

  def create
    @remote_auth = params["remote_auth"]
    begin
      @user = User.by_login(params[:session][:login].downcase)
    rescue NoMethodError => error
      Rails.logger.error "Error caught fetching user details.\nCause: #{error}\n" + error.backtrace.join("\n")
    end

    if !@user.nil? and @user.password == params[:session][:password]
      sign_in @user
      add_user_activity("login", request.env['HTTP_USER_AGENT'])
      update_user_intercom(@user)
      session[:referral_url] = nil
      if params[:session][:widget].blank?
        if @remote_auth.eql?("true")
          create_to_zoho_and_login(@user)
        elsif session[:redirect_url]
          url = session[:redirect_url]
          Rails.logger.debug "Redirecting to #{url}."
          session[:redirect_url] = nil
          redirect_to "#{url}#{params[:session][:anchor]}"
        else
          single_camera_redirection(cameras_index_path)
        end
      else
        render json: {success: true}
      end
    else
      Rails.logger.warn "Invalid user name and/or password specified."
      flash.now[:error] = 'Invalid login/password combination'
      render 'new'
    end
  end

  def destroy
    add_user_activity("logout", request.env['HTTP_USER_AGENT'])
    sign_out
    redirect_to signin_path
  end

  def do_remote_login(user)
    ts = Time.new.utc.to_i
    email = user.email
    remoteauthkey = ENV['REMOTE_AUTH_KEY']
    operation = "signin"

    apikey = Digest::MD5.hexdigest("#{operation}#{email}#{remoteauthkey}#{ts}")
    redirectURL = "https://support.evercam.io/support/RemoteAuth?operation=#{URI::encode(operation, "UTF8")}&email=#{URI::encode(email,"UTF8")}&ts=#{URI::encode("#{ts}","UTF8")}&apikey=#{apikey}"
    redirect_to redirectURL
  end


  def create_to_zoho_and_login(user)
    email = user.email
    ts = Time.new.utc.to_i
    remoteauthkey = ENV['REMOTE_AUTH_KEY']
    operation = "signup"
    utype = "portal"
    fullName = user.fullname
    loginName = "#{user.firstname.downcase}.#{user.lastname.downcase}".gsub(" ", ".")
    apikey = Digest::MD5.hexdigest("#{operation}#{email}#{loginName}#{fullName}#{utype}#{remoteauthkey}#{ts}")
    redirectURL = "https://support.evercam.io/support/RemoteAuth?operation=#{URI::encode(operation)}&email=#{URI::encode(email)}&fullname=#{URI::encode(fullName)}&loginname=#{URI::encode(loginName)}&utype=#{URI::encode(utype)}&ts=#{URI::encode("#{ts}")}&apikey=#{apikey}"
    redirect_to redirectURL
  end

  def is_remote_auth_req
    !request.referer.nil? && request.referer.include?("support.evercam.io")
  end
end
