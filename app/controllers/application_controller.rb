class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # before_action :log_request_details if Rails.env.production?

  def after_sign_in_path_for(_resource)
    top_page_login_url(protocol: 'https')
  end

  private

  # def log_request_details
  #   Rails.logger.info "DEBUG: IP=#{request.ip}, RemoteIP=#{request.remote_ip}, X-Forwarded-Proto=#{request.headers['X-Forwarded-Proto']}, SSL?=#{request.ssl?}"
  # end

  def redirect_if_authenticated
    return unless user_signed_in?

    redirect_to top_page_login_path
  end
end
