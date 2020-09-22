require 'yaml'
require 'dotenv'
require 'erb'

module Evercam
  class Config
    class << self

      # local .env
      Dotenv.load

      def [](key)
        settings[env][key]
      end

      def settings
        @settings ||= (YAML.load(
          ERB.new(File.read(File.join(Dir.getwd, 'config', 'settings.yaml'))).
          result))
      end

      def env
        (ENV['EVERCAM_ENV'] || 'development').to_sym
      end

    end
  end
end

