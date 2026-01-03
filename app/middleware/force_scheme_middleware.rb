class ForceSchemeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    proto = env['HTTP_X_FORWARDED_PROTO']
    Rails.logger.info "DEBUG: Middleware raw proto: '#{proto}'"
    Rails.logger.info "DEBUG: Middleware keys: #{env.keys.select { |k| k.include?('FORWARDED') }}"

    if proto == 'https'
      env['rack.url_scheme'] = 'https'
      env['HTTPS'] = 'on'
      Rails.logger.info 'DEBUG: Middleware forced HTTPS'
    else
      Rails.logger.info 'DEBUG: Middleware DID NOT force HTTPS'
    end
    @app.call(env)
  end
end
