Devise.setup do |config|
  config.mailer_sender = 'cocoja0725@gmail.com'

  require 'devise/orm/active_record'

  config.case_insensitive_keys = [:email]

  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]

  config.stretches = Rails.env.test? ? 1 : 12

  config.allow_unconfirmed_access_for = 0.days

  config.reconfirmable = true

  config.confirm_within = 1.day

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 6..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_in_after_reset_password = true

  config.scoped_views = true

  config.sign_out_via = :delete

  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.sign_in_after_change_password = true

  config.omniauth :google_oauth2,
                  Rails.application.credentials.dig(:google_oauth, :client_id),
                  Rails.application.credentials.dig(:google_oauth, :client_secret),
                  {
                    scope: 'email, profile',
                    prompt: 'select_account',
                    image_aspect_ratio: 'square',
                    image_size: 50,
                      redirect_uri: Rails.env.production? ? "https://#{ENV.fetch('APP_DOMAIN', 'cocoja-613ycaap.b4a.run')}/users/auth/google_oauth2/callback" : nil
                  }

  config.navigational_formats = ['*/*', :html, :turbo_stream]
  config.sign_in_after_reset_password = true
end
