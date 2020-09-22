module SessionsHelper
  def sign_in(user)
    session[:user] = (user ? user.email : nil)
    return unless user
    user.last_login_at = Time.now.utc
    user.save
    @current_user = user
  end

  def sign_out
    session.clear
    @current_user = nil
  end

  def signed_in?
    !@current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.where(Sequel.ilike(:email, session[:user])).first
  end

  def refresh_user
    @current_user = User.where(Sequel.ilike(:email, session[:user])).first
  end

  def allow_iframe
    headers['X-Frame-Options'] = 'ALLOWALL'
  end

  def single_camera_redirection(redirect_camera_url)
    @all_cameras = load_user_cameras(true, false)
    if @all_cameras.count > 1
      redirect_to remove_param_credentials(redirect_camera_url)
    elsif @all_cameras.count < 1
      redirect_to remove_param_credentials(redirect_camera_url)
    else
      redirect_to "#{remove_param_credentials(redirect_camera_url)}/#{@all_cameras.first['id']}".gsub("?", '')
    end
  end

  def remove_param_credentials(original_url)
    require 'uri'

    uri = URI original_url
    params = Rack::Utils.parse_query uri.query
    params.delete('api_id')
    params.delete('api_key')
    uri.query = params.to_param
    uri.to_s
  end
end
