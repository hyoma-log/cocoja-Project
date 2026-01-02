class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :ensure_https_scheme

  private

  def ensure_https_scheme
    return unless request.headers['X-Forwarded-Proto'] == 'https'

    request.env['rack.url_scheme'] = 'https'
    request.env['HTTPS'] = 'on'
  end

  public

  def after_sign_in_path_for(_resource)
    top_page_login_url(protocol: 'https')
  end

  private

  def redirect_if_authenticated
    return unless user_signed_in?

    redirect_to top_page_login_path
  end
end
