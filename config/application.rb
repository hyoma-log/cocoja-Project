require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.assets.initialize_on_precompile = false
    config.assets.enabled = true
    config.assets.version = '1.0'

    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[ja en]
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s]

    config.action_controller.forgery_protection_origin_check = false

    config.time_zone = 'Asia/Tokyo'

    config.active_record.default_timezone = :utc

    config.generators do |g|
      g.skip_routes true
      g.assets false
      g.helper false
      g.test_framework :rspec,
                       fixtures: true,
                       view_specs: false,
                       helper_specs: false,
                       routing_specs: false,
                       controller_specs: false,
                       request_specs: true
    end

    config.autoload_paths += %W[#{config.root}/app/helpers]
  end
end
