module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        skip_before_action :authenticate_user!, only: :create

        def create
          result = ::Auth::RegisterUser.new(
            registration_params.merge(
              ip_address: request.remote_ip,
              user_agent: request.user_agent
            )
          ).call

          set_session_cookie(result[:session])
          render json: user_json(result[:user]), status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end

        def destroy
          ::Auth::DeleteAccount.new(current_user).call
          cookies.delete(:session_token)
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
