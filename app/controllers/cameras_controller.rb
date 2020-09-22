class CamerasController < ApplicationController
  before_action :authenticate_user!, :except=>[:single, :test]
  include SessionsHelper
  include ApplicationHelper
  include CamerasHelper
  require 'socket'
  require 'timeout'

  def index
    @cameras = load_user_cameras(true, false)
    @camera_count = @cameras.count
    @show_alert_message = false
    @required_licences = 0
  end

  def new
    @cameras = load_user_cameras(true, false)
    @user = (flash[:user] || {})
    @ip = request.remote_ip
    if @user == {} && params[:id]
      camera = get_evercam_api.get_camera(params[:id], false)
      @user['camera-id'] = camera['id']
      @user['camera-username'] = camera['cam_username']
      @user['camera-password'] = camera['cam_password']
      @user['camera-url'] = camera.deep_fetch('external', 'host')
      @user['port'] = camera.deep_fetch('external', 'http', 'port') {}
      @user['ext-rtsp-port'] = camera.deep_fetch('external', 'rtsp', 'port') {}
      @user['camera-vendor'] = camera['vendor_id']
      @user['camera-model'] = camera['model_id']
      @user['local-ip'] = camera.deep_fetch('internal', 'host') {}
      @user['local-http'] = camera.deep_fetch('internal', 'http', 'port') {}
      @user['local-rtsp'] = camera.deep_fetch('internal', 'rtsp', 'port') {}
      if camera.deep_fetch('location') { '' }
        @user['camera-lat'] = camera.deep_fetch('location', 'lat') {}
        @user['camera-lng'] = camera.deep_fetch('location', 'lng') {}
      end
      if camera.deep_fetch('external', 'http', 'jpg') { '' }
        @user['snapshot'] = camera.deep_fetch('external', 'http', 'jpg') { '' }.
          sub("http://#{camera.deep_fetch('external', 'host') { '' }}", '').
          sub(":#{camera.deep_fetch('external', 'http', 'port') { '' }}", '')
      end
      if camera.deep_fetch('external', 'rtsp', 'h264') { '' }
        @user['rtsp'] = camera.deep_fetch('external', 'rtsp', 'h264') { '' }.
          sub("rtsp://#{camera.deep_fetch('external', 'host') { '' }}", '').
          sub(":#{camera.deep_fetch('external', 'rtsp', 'port') { '' }}", '')
      end
    end
  end

  def create
    begin
      raise "No camera name specified in request." if params['camera-name'].blank?

      body = {external_host: params['camera-url'], jpg_url: params['snapshot']}
      body[:cam_username] = params['camera-username'] unless params['camera-username'].blank?
      body[:cam_password] = params['camera-password'] unless params['camera-password'].blank?
      body[:vendor] = params['camera-vendor'] unless params['camera-vendor'].blank?
      body[:model] = params["camera-model"] unless params["camera-model"].blank? if body[:vendor]
      body[:internal_http_port] = params['local-http'] unless params['local-http'].blank?
      body[:external_http_port] = params['port'] unless params['port'].blank?
      body[:internal_rtsp_port] = params['local-rtsp'] unless params['local-rtsp'].blank?
      body[:external_rtsp_port] = params['ext-rtsp-port'] unless params['ext-rtsp-port'].blank?
      body[:internal_host] = params['local-ip'] unless params['local-ip'].blank?
      body[:location_lat] = params['camera-lat'] unless params['camera-lat'].blank?
      body[:location_lng] = params['camera-lng'] unless params['camera-lng'].blank?
      body[:status] = "online"
      tzc = TZInfo::Country.get(@current_user.country.iso3166_a2.upcase)
      timezone = Timezone::Zone.new zone:tzc.zone_names.first
      body[:timezone] = timezone.name[:zone]
      api = get_evercam_api
      new_camera = api.create_camera(
        params['camera-name'],
        false,
        body
      )
      redirect_to cameras_single_path(new_camera["id"])
    rescue => error
      flash[:user] = {
        'camera-name' => params['camera-name'],
        'camera-username' => params['camera-username'],
        'camera-password' => params['camera-password'],
        'camera-url' => params['camera-url'],
        'port' => params['port'],
        'ext-rtsp-port' => params['ext-rtsp-port'],
        'snapshot' => params['snapshot'],
        'camera-vendor' => params['camera-vendor'],
        'camera-model' => params['camera-model'],
        'local-ip' => params['local-ip'],
        'local-http' => params['local-http'],
        'local-rtsp' => params['local-rtsp']
      }
      if error.kind_of?(Evercam::EvercamError)
        response = instance_eval{(error.message).first}
        flash[:message] = t("errors.#{error.code}") unless error.code.nil?
        assess_field_errors(response)
      else
        flash[:message] = "An error occurred creating your account. Please check "\
                          "the details and try again. If the problem persists, "\
                          "contact support."
      end
      Rails.logger.error "Exception caught in create camera request.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      if params["add-camera"].present? && params["add-camera"].eql?("test")
        return redirect_to cameras_new_test_path
      else
        return redirect_to cameras_new_path
      end
    end
  end

  def update
    begin
      settings = {
        :name => params['camera_name'],
        :external_host => params['camera_url'],
        :timezone => params['camera_timezone'].blank? ? 'Europe/Dublin' : ActiveSupport::TimeZone.new(params['camera_timezone']).tzinfo.name,
        :internal_host => params['local-ip'],
        :external_http_port => params['port'],
        :internal_http_port => params['local-http'],
        :external_rtsp_port => params['ext_rtsp_port'],
        :nvr_http_port => params["nvr_port"],
        :internal_rtsp_port => params['local_rtsp'],
        :jpg_url => params['snapshot'],
        :h264_url => params['rtsp'],
        :vendor => params['camera_vendor'],
        :model => params['camera_vendor'].blank? ? '' : params['camera_model'],
        :location_lat => params['cameraLat'],
        :location_lng => params['cameraLng'],
        :cam_username => params['camera_username'],
        :cam_password => params['camera_password']
      }
      get_evercam_api.update_camera(params['id'], settings)
      camera = get_evercam_api.get_camera(params["id"], false)
      result = {success: true, camera: camera}
    rescue => error
      Rails.logger.error "Exception caught updating camera details.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      result = {success: false, message: error.message}
    end
    render json: result
  end

  def delete
    begin
      result = {success: true}
      api = get_evercam_api
      if [true, "true"].include?(params[:share])
        api.delete_camera_share(params[:id], current_user.email)
      else
        if params[:camera_specified_id] && params[:camera_specified_id] == params[:id]
          api.delete_camera(params[:id])
        else
          result = {success: false, message: "Invalid camera id specified."}
        end
      end
    rescue => error
      Rails.logger.error "Exception caught deleting camera.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      message = "An error occurred deleting your camera. Please try again "\
                      "and, if the problem persists, contact support."
      result = {success: false, message: message}
    end
    render json: result
  end

  def single
    begin
      if params[:api_id] and params[:api_key]
        authenticate_user!
      end
      @archive_view = false
      api = get_evercam_api
      if @current_user
        @cameras = load_user_cameras(true, false)
        @has_shared = false
        @cameras.map do |c|
          if c['id'].eql?(params[:id])
            @camera = c
            @has_shared = true if @camera['owner'] != current_user.username
            break
          end
        end
        @is_owner = @camera['owner'] == current_user[:username]? true : false
        @user_time = Time.new.in_time_zone(@camera['timezone'])
        @selected_date = @user_time.strftime("%m/%d/%Y")
        @current_time = @user_time.strftime("%H")
        @share = nil
        @owner = nil
        unless @is_owner
          return redirect_to cameras_not_found_path if !@has_shared && !@camera['is_public']
          @owner = User.by_login(@camera['owner'])
        else
          @owner = current_user
        end
      end

      params_subpath = params.fetch('subpath', '')
      tab_name = params_subpath.split('/').first
      archive_id = params_subpath.split('/').last
      if @current_user.nil? && !tab_name.eql?(archive_id)
        @archive_view = true
        @archive = api.get_archive(params[:id], archive_id)
        @camera_id = @archive['camera_id']
        @archive_id = @archive['id']
        @archive_type = "clip"
        if @archive['type'].eql?("compare")
          @archive_type = "compare"
        end
      else
        @camera = api.get_camera(params[:id], true) if @camera.nil?
        @camera['status'] = "offline" if @camera['status'].blank?
        @has_edit_rights = @camera["rights"].split(",").include?("edit") if @camera["rights"]
        time = ActiveSupport::TimeZone.new(@camera['timezone'])
        @camera['timezone'] = 'Etc/UTC' unless time.utc_offset % 3600 == 0
        time_zone = TZInfo::Timezone.get(@camera['timezone'])
        current = time_zone.current_period
        @offset = current.utc_offset + current.std_offset
      end

      @page = (params[:page].to_i - 1) || 0
      @types = ['accessed', 'viewed', 'edited', 'captured',
        'shared', 'stopped sharing', 'online', 'offline',
        'cloud recordings updated', 'cloud recordings created',
        'archive created', 'archive deleted']

      @camera_shares = nil
      @share_requests = nil
      @cloud_recording = @camera["cloud_recordings"] if @has_edit_rights
      @cr_status = nil
      if @cloud_recording.nil?
        @cr_status = true
        @cloud_recording = get_default_settings
      end
      @snapshot_navigator = false
      @ip = request.remote_ip
    rescue => error

      if error.try(:status_code).present? && error.status_code.equal?(404)
        redirect_to cameras_not_found_path
      else
        Rails.logger.error "Exception caught fetching camera details.\nCause: #{error}\n" +
                             error.backtrace.join("\n")
        flash[:error] = "An error occurred fetching the details for your camera. "\
                      "Please try again and, if the problem persists, contact "\
                      "support."
        redirect_to cameras_not_found_path
      end
    end
  end

  def map
    @cameras = load_user_cameras(true, false)
    @map_data = @cameras.map do |camera|
      {
        name: camera["name"],
        id: camera["id"],
        owner: camera["owner"],
        status: camera["status"],
        is_public: camera["is_public"],
        vendor_id: camera["vendor_id"],
        location: camera["location"],
        vendor_name: camera["vendor_name"],
        thumbnail_url: thumbnail_url(camera)
      }
    end
  end

  def online_offline
    @cameras = load_user_cameras(true, false)
  end

  def status_bar_single_camera
    api = get_evercam_api
    new_params = {}
    new_params[:types] = "online,offline"
    new_params[:from] = Time.at(params['from'].to_i).iso8601
    new_params[:to] = Time.at(params['to'].to_i).iso8601
    new_params[:limit] = 10000
    all_logs = api.get_logs(params["camera_id"], new_params)
    sorted_logs = all_logs[:logs].sort_by {|log| log["done_at"]}
    days = (Time.at(params['to'].to_i) - Time.at(params['from'].to_i)).to_i / 86400
    camera_timezone = params["timezone"]

    @camera_logs = {
      camera_name: params["camera_name"],
      status: humanize_status(params["camera_status"]),
      created_at: Time.at(params["created_at"].to_i).utc,
      logs: map_single_camera_logs(sorted_logs)
    }

    @formated_data = {
      measure_html: create_measure(@camera_logs[:camera_name], @camera_logs[:status]),
      data: format_logs(@camera_logs[:status], @camera_logs[:logs], camera_timezone, @camera_logs[:created_at], days)
    }

    render json: [@formated_data].to_json.html_safe
  end

  def humanize_status(status)
    if status == "online"
      true
    else
      false
    end
  end

  def update_status_report
    days = if params[:history_days].to_i != 0 then params[:history_days].to_i else 7 end
    initial_cameras = load_user_cameras(true, false)
    if params["offline_only"] == "true" || params["offline_only"] == true
      @cameras = initial_cameras.reject {|cam| cam["status"] == "online" }
    else
      @cameras = initial_cameras
    end
    camera_exids = []
    @cameras.each do |camera|
      camera_exids[camera_exids.count] =  camera["id"]
    end

    @all_cameras = Camera.where(exid: camera_exids).all
    camera_ids = []
    @all_cameras.each do |camera|
      camera_ids[camera_ids.count] =  camera.id
    end
    CameraActivity.dataset = Sequel.connect(ENV['SNAPSHOT_DATABASE_URL'], max_connections: 100)[:camera_activities]

    all_logs = CameraActivity
                .where(camera_id: camera_ids)
                .where(:action => ["online", "offline"])
                .where(:done_at => (Date.today - days)..(Time.now.utc))
                .order(:done_at).all

    @camera_logs = @cameras.map do |camera|
      {
        camera_name: camera["name"],
        status: camera["status"],
        created_at: Time.iso8601(camera["created_at"]).utc,
        logs: map_logs(all_logs, camera["id"])
      }
    end

    @formated_data = @camera_logs.map do |camera_log|
      {
        measure: create_measure(camera_log[:camera_name], camera_log[:status]),
        data: format_logs(camera_log[:status], camera_log[:logs], "Etc/UTC", camera_log[:created_at], days)
      }
    end
    render json: @formated_data.to_json.html_safe
  end

  def create_measure(camera_name, status)
    if status == true
      "#{camera_name}"
    else
      "#{camera_name} (offline)"
    end
  end

  def map_logs(all_logs, id)
    if all_logs.select{|i| i[:camera_exid] == id}.empty?
      []
    else
      all_logs.select{|i| i[:camera_exid] == id}.map do |log|
        {
          done_at: log[:done_at],
          action: log[:action]
        }
      end
    end
  end

  def map_single_camera_logs(all_logs)
    if all_logs.empty?
      []
    else
      all_logs.map do |log|
        {
          done_at: Time.iso8601(log["done_at"]).utc,
          action: log["action"]
        }
      end
    end
  end

  def cameras_table
    @cameras = load_user_cameras(true, false)
  end

  def format_logs(status, logs, timezone, created_at, days)
    starting_of_week = Time.now.utc.beginning_of_day - (days * 24 * 60 * 60)
    no_event_logged = if starting_of_week < created_at then created_at else starting_of_week end
    if logs.count >= 1
      logs.unshift({
        done_at: no_event_logged,
        action: if logs[0][:action] == "online" then "offline" else "online" end
      })
    end
    if logs == [] && status == false
      [[format_date_time(no_event_logged), 0, format_date_time(Time.now.utc)]]
    elsif logs == [] && status == true
      [[format_date_time(no_event_logged), 1, format_date_time(Time.now.utc)]]
    elsif logs.count > 1
      logs.map.with_index do |log, index|
        [format_date_time(log[:done_at].in_time_zone(timezone)), digit_status(log[:action]), done_at_with_index(logs, index + 1, timezone)]
      end
    end
  end

  def done_at_with_index(logs, index, timezone)
    if index > logs.length - 1
      Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
    else
      logs[index][:done_at].in_time_zone(timezone).strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  def format_date_time(done_at)
    done_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def digit_status(action)
    if action == "online"
      1
    else
      0
    end
  end

  def camera_not_found
    begin
      @cameras = load_user_cameras(true, false)
    rescue => error
      Rails.logger.error "Exception caught fetching user cameras.\nCause: #{error}\n" +
                           error.backtrace.join("\n")
      flash[:error] = "An error occurred fetching user cameras. "\
                      "Please try again and, if the problem persists, contact "\
                      "support."
      redirect_to cameras_index_path
    end
  end

  def server_down
    @cameras = []
  end

  def transfer
    result = {success: true}
    begin
      raise BadRequestError.new("No camera id specified in request.") unless params.include?(:camera_id)
      raise BadRequestError.new("No user email specified in request.") unless params.include?(:email)
      get_evercam_api.change_camera_owner(params[:camera_id], params[:email])
    rescue => error
      Rails.logger.error "Exception caught transferring camera ownership.\nCause: #{error}\n" +
          error.backtrace.join("\n")
      message = "An error occurred transferring ownership of this camera. Please "\
                "try again and, if the problem persists, contact support."
      result = {success: false, message: message, error: "#{error}"}
    end
    render json: result
  end

  def request_clip
    result = {success: true}
    begin
      api = get_evercam_api
      camera = api.get_camera(params[:id], true)
      from_date = DateTime.parse(params['from_date']).to_i
      to_date = DateTime.parse(params['to_date']).to_i

      api.create_archive(camera["id"], params["title"], from_date, to_date,
        current_user.username, params["embed_time"], params["is_public"])
      result[:message] = "Your clip has been requested."
    rescue => error
      result = {success: false, message: error.message}
    end
    render json: result
  end

  def delete_clip
    result = {success: true}
    begin
      api = get_evercam_api
      api.delete_archive(params[:camera_id], params[:archive_id])
      result[:message] = "Archive deleted successfully."
    rescue => error
      result = {success: false, message: error.message}
    end
    render json: result
  end

  def log_intercom
    if Evercam::Config.env == :production
      intercom = Intercom::Client.new(
          app_id: Evercam::Config[:intercom][:app_id],
          api_key: Evercam::Config[:intercom][:api_key]
      )
      begin
        ic_user = intercom.users.find(:user_id => current_user.username)
      rescue
        # Intercom::ResourceNotFound
        # Ignore it
      end
      unless ic_user.nil?
        begin
          if params["view"].present?
            viewed_count = ic_user.custom_attributes["viewed_camera"].to_i
            ic_user.custom_attributes = {"viewed_camera": viewed_count + 1}
          elsif params["recordings"].present?
            viewed_count = ic_user.custom_attributes["viewed_recordings"].to_i
            ic_user.custom_attributes = {"viewed_recordings": viewed_count + 1}
          elsif params["has_shared"].present?
            ic_user.custom_attributes = {"has_shared": true}
          elsif params["has_snapmail"].present?
            ic_user.custom_attributes = {"has_snapmail": true}
          end
          intercom.users.save(ic_user)
        rescue
          # Ignore it
        end
      end
    end
    render json: {success: true}
  end

  def test
    api = get_evercam_api
    if @current_user
      @cameras = load_user_cameras(true, false)
    end
  end

  private

  def get_default_settings
    {
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

  def assess_field_errors(error)
    field_errors = {}
    field_errors[error.first] = error.last.first
    flash[:field_errors] = field_errors
  end
end
