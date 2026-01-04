require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  config.cache_store = :redis_cache_store, {
    url: ENV.fetch('REDIS_URL', nil),
    namespace: 'cache',
    expires_in: 1.day
  }

  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=31536000, immutable'
  }
  config.assets.compile = false
  config.assets.digest = true
  config.assets.version = '1.0'

  config.force_ssl = false

  config.action_controller.default_url_options = { protocol: 'https' }

  # config.action_dispatch.trusted_proxies = [IPAddr.new('0.0.0.0/0')]

  config.ssl_options = {
    hsts: { subdomains: true, preload: true, expires: 1.year },
    redirect: {
      exclude: lambda { |request|
        request.get_header('HTTP_X_FORWARDED_PROTO') == 'https'
      }
    }
  }

  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  config.log_level = :info

  config.i18n.fallbacks = true

  config.active_record.dump_schema_after_migration = false

  config.require_master_key = true

  config.action_cable.disable_request_forgery_protection = false
  config.action_cable.allowed_request_origins = [%r{http://*}, %r{https://*}]

  config.action_mailer.default_url_options = { host: ENV.fetch('APP_DOMAIN', 'www.cocoja.jp'),
protocol: 'https' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               ENV.fetch('APP_DOMAIN', 'www.cocoja.jp'),
    user_name:            Rails.application.credentials.dig(:gmail, :username),
    password:             Rails.application.credentials.dig(:gmail, :password),
    authentication:       'plain',
    enable_starttls_auto: true,
    open_timeout:         5,
    read_timeout:         5
  }
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
end
