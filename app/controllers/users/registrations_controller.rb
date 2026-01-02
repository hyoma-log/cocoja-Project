module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]

    def create
      Rails.logger.info 'DEBUG: Starting RegistrationsController#create'
      begin
        super do |resource|
          Rails.logger.info "DEBUG: User saved? #{resource.persisted?}"
          if resource.persisted?
            Rails.logger.info "DEBUG: User ID: #{resource.id}"
          else
            Rails.logger.error "DEBUG: User save FAILED. Errors: #{resource.errors.full_messages}"
          end
        end
      rescue StandardError => e
        Rails.logger.error "DEBUG: FATAL EXCEPTION in RegistrationsController#create: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
      Rails.logger.info 'DEBUG: Finished RegistrationsController#create'
    end

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[terms_agreement privacy_agreement])
    end

    def after_sign_up_path_for(_resource)
      new_user_session_path
    end

    def after_inactive_sign_up_path_for(_resource)
      new_user_session_path
    end
  end
end
