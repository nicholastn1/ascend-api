module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        skip_before_action :authenticate_user!, only: :create

        def create
          if ENV["FLAG_DISABLE_SIGNUPS"] == "true"
            render json: { error: "Signups are currently disabled" }, status: :forbidden
            return
          end

          if ENV["FLAG_DISABLE_EMAIL_AUTH"] == "true"
            render json: { error: "Email authentication is disabled" }, status: :forbidden
            return
          end

          result = ::Auth::RegisterUser.new(
            registration_params.merge(
              ip_address: request.remote_ip,
              user_agent: request.user_agent
            )
          ).call

          set_session_cookie(result[:session])
          render json: user_json(result[:user]), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_content
        end

        def destroy
          ::Auth::DeleteAccount.new(current_user).call
          delete_session_cookie
          render json: { message: "Account deleted" }
        end

        private

        def registration_params
          params.permit(:name, :email, :username, :password)
        end
      end
    end
  end
end
