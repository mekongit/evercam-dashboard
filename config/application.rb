require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "active_record/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require "evercam"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module EvercamDashboard
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    GC::Profiler.enable

    config.websockets_url = "wss://media.evercam.io/socket"
    config.action_dispatch.default_headers.merge!('X-UA-Compatible' => 'IE=edge')

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.initialize_on_precompile = true

    config.assets.paths << "#{Rails.root.to_s}/vendor/assets/fonts"
    config.assets.paths << "#{Rails.root.to_s}/vendor/assets/javascripts"
    config.assets.paths << "#{Rails.root.to_s}/lib/assets/javascripts"
    config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
    config.assets.precompile += %w[*.png *.jpg *.jpeg *.gif *.svg *.woff *.woff2]
    config.assets.precompile += %w[
      live_view_private_widget.js
      snapshot_navigator_widget.js
      admin/admin.js
      admin/admin.css
      views/widgets/widget.css
      views/widgets/add_camera.css
      videojs/video-js.min
      bare-bones.js
      good_bye.scss
      widgets.js
      jquery.js
      phoenix.js
      widgets.scss
      clip_play.scss
    ]
  end
end
