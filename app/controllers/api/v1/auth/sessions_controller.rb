module Api
  module V1
    module Auth
      class SessionsController < BaseController
        skip_before_action :authenticate_user!, only: :create

        def create
          if ENV["FLAG_DISABLE_EMAIL_AUTH"] == "true"
            render json: { error: "Email authentication is disabled" }, status: :forbidden
            return
          end

          result = ::Auth::AuthenticateUser.new(
            email: params[:email],
            password: params[:password],
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          ).call

          if result[:requires_2fa]
            # Return a temporary token for 2FA verification
            temp_token = JWT.encode(
              { user_id: result[:user].id, purpose: "2fa", exp: 5.minutes.from_now.to_i },
              Rails.application.secret_key_base
            )
            render json: { requires_2fa: true, temp_token: temp_token }
          else
            set_session_cookie(result[:session])
            render json: user_json(result[:user])
          end
        rescue ::Auth::AuthError => e
          render json: { error: e.message }, status: :unauthorized
        end

        def show
          render json: user_json(current_user)
        end

        def destroy
          token = cookies.signed[:session_token] || request.headers["Authorization"]&.delete_prefix("Bearer ")
          Session.find_by_token(token)&.destroy
          delete_session_cookie
          render json: { message: "Logged out" }
        end
      end
    end
  end
end
