module Users
  class RegistrationsController < Devise::RegistrationsController
    # def create
    #   super
    # end

    protected

    def after_sign_up_path_for(_resource)
      new_user_session_path
    end

    def after_inactive_sign_up_path_for(_resource)
      new_user_session_path
    end
  end
end
