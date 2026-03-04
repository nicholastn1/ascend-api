module Api
  module V1
    module Auth
      class EmailVerificationsController < BaseController
        skip_before_action :authenticate_user!

        def create
          user = User.find_by(confirmation_token: params[:token])
          if user.nil?
            render json: { error: "Invalid token" }, status: :unprocessable_entity
            return
          end

          user.update!(
            email_verified: true,
            confirmed_at: Time.current,
            confirmation_token: nil
          )
          render json: { message: "Email verified" }
        end
      end
    end
  end
end
