module Api
  module V1
    module Auth
      class TwoFactorController < BaseController
        skip_before_action :authenticate_user!, only: :validate

        def setup
          result = ::Auth::ManageTwoFactor.new(current_user).setup
          result[:two_factor].save!
          render json: { secret: result[:secret], uri: result[:uri] }
        end

        def verify
          result = ::Auth::ManageTwoFactor.new(current_user).verify_and_enable(params[:code])
          render json: { backup_codes: result[:backup_codes] }
        rescue ::Auth::AuthError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def validate
          # Validate 2FA code during login (using temp_token from login response)
          payload = JWT.decode(params[:temp_token], Rails.application.secret_key_base).first
          raise ::Auth::AuthError, "Invalid token" unless payload["purpose"] == "2fa"

          user = User.find(payload["user_id"])
          ::Auth::ManageTwoFactor.new(user).validate(params[:code])

          session = user.sessions.create!(
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          set_session_cookie(session)
          render json: user_json(user)
        rescue JWT::ExpiredSignature, JWT::DecodeError
          render json: { error: "Token expired or invalid" }, status: :unauthorized
        rescue ::Auth::AuthError => e
          render json: { error: e.message }, status: :unauthorized
        end

        def destroy
          ::Auth::ManageTwoFactor.new(current_user).disable
          render json: { message: "2FA disabled" }
        end
      end
    end
  end
end
