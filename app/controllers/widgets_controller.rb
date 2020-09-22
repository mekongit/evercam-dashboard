class WidgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :allow_iframe, only: [:live_view_private_widget, :hikvision_private_widget, :snapshot_navigator_widget, :sessions]
  after_action :allow_iframe, only: [:hikvision_private_widget, :live_view_private_widget, :snapshot_navigator_widget, :sessions]
  before_action :allow_iframe, only: [:live_view_private_widget, :snapshot_navigator_widget, :sessions]
  before_action :normal_cookies_for_ie_in_iframes!, only: [:live_view_private_widget, :hikvision_private_widget, :snapshot_navigator_widget]
  skip_before_action :verify_authenticity_token, only: [:live_view_widget, :hikvision_local_storage, :snapshot_navigator, :live_view_private_widget, :hikvision_private_widget, :snapshot_navigator_widget]
  skip_before_action :authenticate_user!, only: [:live_view_widget, :hikvision_local_storage, :snapshot_navigator, :live_view_private_widget, :hikvision_private_widget, :snapshot_navigator_widget]

  include SessionsHelper
  include ApplicationHelper

  def widgets
    current_user
  end

  def widget
    begin
      authenticate_user

      @cameras = load_user_cameras(true, false)
      api = get_evercam_api
      @camera = api.get_camera(params[:camera], true)
      @has_edit_rights  = @camera["rights"].split(",").include?("edit") if @camera["rights"]
      @camera['timezone'] = 'Etc/GMT+1' unless @camera['timezone']
      time_zone         = TZInfo::Timezone.get(@camera['timezone'])
      current           = time_zone.current_period
      @offset           = current.utc_offset + current.std_offset
      @selected_date    = Time.new.in_time_zone(@camera['timezone']).strftime("%m/%d/%Y")
      @cloud_recording = @camera["cloud_recordings"] if @has_edit_rights
      if @cloud_recording.nil?
        @cloud_recording = {
          "frequency" => 1,
          "status" => "off",
          "storage_duration" => 1,
          "schedule" => {
            "Monday" => ["00:00-23:59"],
            "Tuesday" => ["00:00-23:59"],
            "Wednesday" => ["00:00-23:59"],
            "Thursday" => ["00:00-23:59"],
            "Friday" => ["00:00-23:59"],
            "Saturday" => ["00:00-23:59"],
            "Sunday" => ["00:00-23:59"]
          }
        }
      end
      render :layout => true
    rescue => error
      Rails.logger.error "Exception caught in snapshot navigator.\nCause: #{error}\n" +
                             error.backtrace.join("\n")
      flash[:message] = error.message
    end
  end

  def widgets_new
    @cameras = load_user_cameras(true, false)
    render layout: "dev"
  end

  def live_view_widget
    begin
      api = get_evercam_api
      @camera = api.get_camera(params[:camera], true)
    rescue
      @camera = {}
    end
    respond_to do |format|
      format.js { render :file => "widgets/live.view.widget.js.erb", :mime_type => Mime::Type.lookup('text/javascript')}
    end
  end

  def live_view_private_widget
    if params[:camera] == "central-bank-fusion" && request.ip != "217.112.145.202"
      @unathorized = true
    end

    if params["private"]
      authenticate_user
      unless current_user.nil?
        render :layout => false
      end
      begin
        api = get_evercam_api
        api.get_snapshot(params[:camera])
      rescue => error
        if error.try(:status_code).present?
          @unathorized = error.status_code == 403
          @not_exist = error.status_code == 404
        end
      end
    else
      render :layout => false
    end
  end

  def widgets_hikvision
    @cameras = load_user_cameras(true, false)
    render layout: "dev"
  end

  def hikvision_local_storage
    respond_to do |format|
      format.js { render :file => "widgets/hikvision.local.storage.js", :mime_type => Mime::Type.lookup('text/javascript')}
    end
  end

  def hikvision_private_widget
    authenticate_user
    unless current_user.nil?
      render :layout => false
    end
  end

  def widget_snapshot_navigator
    @cameras = load_user_cameras(true, false)
    render layout: "dev"
  end

  def snapshot_navigator
    respond_to do |format|
      format.js { render :file => "widgets/snapshot.navigator.widget.js.erb", :mime_type => Mime::Type.lookup('text/javascript')}
    end
  end

  def snapshot_navigator_widget
    begin
      authenticate_user

      api               = get_evercam_api
      @camera           = api.get_camera(params[:camera], true)
      @has_edit_rights  = @camera["rights"].split(",").include?("edit") if @camera["rights"]
      @camera['timezone'] = 'Etc/GMT+1' unless @camera['timezone']
      time_zone         = TZInfo::Timezone.get(@camera['timezone'])
      current           = time_zone.current_period
      @offset           = current.utc_offset + current.std_offset
      @selected_date    = Time.new.in_time_zone(@camera['timezone']).strftime("%m/%d/%Y")
      @cloud_recording = api.get_cloud_recordings(params[:camera]) if @has_edit_rights
      if @cloud_recording.nil?
        @cloud_recording = {
          "frequency" => 1,
          "status" => "off",
          "storage_duration" => 1,
          "schedule" => {
            "Monday" => ["00:00-23:59"],
            "Tuesday" => ["00:00-23:59"],
            "Wednesday" => ["00:00-23:59"],
            "Thursday" => ["00:00-23:59"],
            "Friday" => ["00:00-23:59"],
            "Saturday" => ["00:00-23:59"],
            "Sunday" => ["00:00-23:59"]
          }
        }
      end
      render :layout => false
    rescue => error
      Rails.logger.error "Exception caught in snapshot navigator.\nCause: #{error}\n" +
                             error.backtrace.join("\n")
      flash[:message] = error.message
    end
  end

  def widget_add_camera
    @cameras = load_user_cameras(true, false)
    render layout: "dev"
  end

  private

  def authenticate_user
    widget_user = nil
    unless params[:api_id].blank? or params[:api_key].blank?
      widget_user = User.where(api_id: params[:api_id], api_key: params[:api_key]).first
      sign_in(widget_user) if widget_user
    end
    if current_user.nil? and widget_user.nil?
      session[:redirect_url] = request.original_url
      redirect_to widget_signin_path
    end
  end
end
