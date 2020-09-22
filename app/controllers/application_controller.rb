class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  prepend_before_action :authenticate_user!, :set_cache_buster
  rescue_from Exception, :with => :render_error if Rails.env.production?
  helper_method :requested_url_value

  def authenticate_user!
    if current_user.nil? or (params.has_key?(:api_id) and params.has_key?(:api_key))
      user = nil
      redirect_url = request.original_url.remove('404')
      if params.has_key?(:api_id) and params.has_key?(:api_key)
        user = User.where(api_id: params[:api_id], api_key: params[:api_key]).first
      end

      if user.nil?
        session[:redirect_url] = redirect_url
        redirect_to signin_path
      else
        session[:admin_login] = true
        sign_in user
        add_user_activity("login using api_id / api_key", request.env['HTTP_USER_AGENT'])
        update_user_intercom(user)
        single_camera_redirection(redirect_url)
      end
    end
  end

  def requested_url_value
    session[:redirect_url]
  end

  def update_user_intercom(user, old_email = nil)
    if old_email.nil?
      old_email = user.email
    end

    if Evercam::Config.env == :production
      intercom = Intercom::Client.new(token: Evercam::Config[:intercom][:api_key])
      begin
        ic_user = intercom.users.find(:email => old_email)
      rescue
        # Intercom::ResourceNotFound
        # Ignore it
      end
      unless ic_user.nil?
        begin
          ic_user.user_id = user.username
          ic_user.email = user.email
          ic_user.name = user.fullname
          ic_user.last_seen_user_agent = request.user_agent
          ic_user.last_request_at = Time.now.to_i
          ic_user.new_session = true
          if (params.has_key?(:api_id) and params.has_key?(:api_key))
            ic_user.custom_attributes["admin_login"] = "Login via admin. IP: #{request.remote_ip}"
          else
            ic_user.last_seen_ip = request.remote_ip
          end
          if ic_user.custom_attributes["status"].eql?("Shared-Non-Registered")
            ic_user.custom_attributes["status"] = "Share-Accepted"
          end
          intercom.users.save(ic_user)
        rescue
          # Ignore it
        end
      end
    end
  end

  def get_referral_url
    if !request.referer.nil? && !request.referer.include?("dash.evercam.io")
      session[:referral_url] = request.referer
    end
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def add_user_activity(action, user_agent, camera_id = nil)
    if Evercam::Config.env == :production
      api = get_evercam_api
      api.create_log(action, {}, camera_id)
    end
  end

  def load_user_cameras(shared, thumbnail)
    api = get_evercam_api
    begin
      api.get_user_cameras(current_user.username, shared, thumbnail) if @cameras.blank?
    rescue => error
      Rails.logger.error "[load_cameras_error] [#{current_user.username}] [#{request.remote_ip}] [Cause: #{error.message}]"
      if params[:controller].eql?("cameras") && params[:action].eql?("index")
        redirect_to server_down_path
      end
      []
    end
  end

  # Added before_action to decouple @cameras from users controller
  def ensure_cameras_loaded
    if @cameras.nil?
      load_user_cameras(true, false)
    end
  end

  private

  def render_error(exception)
    if exception.message.eql?("ActionController::InvalidAuthenticityToken")
      redirect_to signin_path
    else
      Rails.logger.error exception.message
      render :file => "#{Rails.root}/public/500.html", :layout => false, :status => 500
    end
  end
end
