TIMEOUT = 5

def evercam_media_api_url
  settings    = EvercamDashboard::Application.config.evercam_media_api
  scheme      = (settings[:scheme] || "https")
  host        = (settings[:host] || "media.evercam.io")
  host        = "#{host}:#{settings[:port]}" if settings.include?(:port)
  "#{scheme}://#{host}/v2/"
end

begin
  EVERCAM_API       = evercam_media_api_url
  EVERCAM_MEDIA_API = evercam_media_api_url
rescue
  EVERCAM_API       = 'https://media.evercam.io/v2/'
  EVERCAM_MEDIA_API = 'https://media.evercam.io/v2/'
end
