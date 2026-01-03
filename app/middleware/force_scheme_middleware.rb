class ForceSchemeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Log all relevant headers for debugging
    forwarded_keys = env.keys.select { |k| k.include?('FORWARDED') }
    forwarded_keys.each do |k|
      Rails.logger.info "DEBUG: #{k} = '#{env[k]}'"
    end

    # Check X-Forwarded-Proto OR CloudFront-Forwarded-Proto
    proto = env['HTTP_X_FORWARDED_PROTO']
    cf_proto = env['HTTP_CLOUDFRONT_FORWARDED_PROTO']

    if proto == 'https' || cf_proto == 'https'
      env['rack.url_scheme'] = 'https'
      env['HTTPS'] = 'on'
      Rails.logger.info "DEBUG: Middleware forced HTTPS (Match: #{proto == 'https' ? 'Proto' : 'CloudFront'})"
    else
      Rails.logger.info 'DEBUG: Middleware DID NOT force HTTPS'
    end
    @app.call(env)
  end
end
