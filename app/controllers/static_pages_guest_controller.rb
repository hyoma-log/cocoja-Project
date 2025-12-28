class StaticPagesGuestController < ApplicationController
  skip_before_action :authenticate_user!, only: [:top]

  before_action :redirect_if_authenticated, only: [:top]

  def top; end

  private

  def redirect_if_authenticated
    redirect_to top_page_login_url(protocol: 'https') if user_signed_in?
  end
end
