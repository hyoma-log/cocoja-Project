class ForceSchemeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_X_FORWARDED_PROTO'] == 'https'
      env['rack.url_scheme'] = 'https'
      env['HTTPS'] = 'on'
    end
    @app.call(env)
  end
end
