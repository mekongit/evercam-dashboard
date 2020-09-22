module ApplicationHelper
  include SessionsHelper

  def avatar_url(email)
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "//gravatar.com/avatar/#{gravatar_id}"
  end

  def timezones
    Timezone::Zone.names.to_a
  end

  def is_active?(link_path)
    current_page?(link_path) ? 'active' : ''
  end

  def get_evercam_api
    configuration = Rails.application.config
    parameters = {logger: Rails.logger}

    if current_user
      parameters = parameters.merge(
        api_id: current_user.api_id,
        api_key: current_user.api_key,
        agent: request.env['HTTP_USER_AGENT'],
        requester_ip: request.remote_ip
      )
      parameters = parameters.merge(get_country_code())
    end
    settings = {}
    begin
      settings = (configuration.evercam_api || {})
    rescue => _error
      # Deliberately ignored.
    end
    parameters = parameters.merge(settings) if !settings.empty?
    Evercam::API.new(parameters)
  end

  def get_country_code
    country_info = {}
    begin
      if session[:country_info].nil? or session[:country_info] == {}
        country_code = request.safe_location.country_code.downcase
        country_code = "ie" if country_code.eql?("")
        code = IsoCountryCodes.find(country_code)
        country_info = country_info.merge(country: code.name, country_code: code.alpha2)
        session[:country_info] = country_info
      else
        country_info = session[:country_info]
      end
    rescue => _e
      # Deliberately ignored.
    end
    country_info
  end

  def format_time stamp
    t = Time.at(stamp)
    t.to_formatted_s(:long)
  end

  # Bug here is rounding amounts, and not showing the cents correctly
  def cents_to_currency amount
    amount / 100
    # number_to_currency(amount / 100, :precision => 2)
  end
end
