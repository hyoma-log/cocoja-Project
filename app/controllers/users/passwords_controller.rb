module Users
  class PasswordsController < Devise::PasswordsController
    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?

      if successfully_sent?(resource)

        flash[:notice] = I18n.t('devise.passwords.send_instructions')
        redirect_to new_user_session_path
      else
        respond_with(resource)
      end
    end

    def update
      user = resource_class.with_reset_password_token(resource_params[:reset_password_token])

      if user.present?
        user.password = resource_params[:password]
        user.password_confirmation = resource_params[:password_confirmation]

        password_valid = user.password.present? &&
                         user.password == user.password_confirmation &&
                         user.password.length >= 6

        if password_valid
          user.reset_password_token = nil
          user.reset_password_sent_at = nil

          if user.save(validate: false)
            self.resource = user
            handle_successful_password_reset
            return
          end
        else
          self.resource = user

          resource.errors.clear

          if user.password.blank?
            resource.errors.add(:password, :blank)
          elsif user.password.length < 6
            resource.errors.add(:password, :too_short, count: 6)
          end

          if user.password != user.password_confirmation
            resource.errors.add(:password_confirmation, :confirmation)
          end
        end
      else
        flash[:alert] = I18n.t('devise.passwords.no_token')
        redirect_to new_user_password_path
        return
      end

      set_minimum_password_length
      respond_with resource
    end

    private

    def handle_successful_password_reset
      resource.unlock_access! if unlockable?(resource)

      if Devise.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end

      respond_with resource, location: after_resetting_password_path_for(resource)
    end
  end
end
