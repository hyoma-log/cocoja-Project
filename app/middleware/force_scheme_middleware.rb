class ForceSchemeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Check X-Forwarded-Proto OR CloudFront-Forwarded-Proto
    proto = env['HTTP_X_FORWARDED_PROTO']
    cf_proto = env['HTTP_CLOUDFRONT_FORWARDED_PROTO']

    if proto == 'https' || cf_proto == 'https'
      env['rack.url_scheme'] = 'https'
      env['HTTPS'] = 'on'
    end
    @app.call(env)
  end
end
