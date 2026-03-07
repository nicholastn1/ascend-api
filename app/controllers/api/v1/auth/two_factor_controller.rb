module Api
  module V1
    module Auth
      class TwoFactorController < BaseController
        skip_before_action :authenticate_user!, only: :validate

        def setup
          # If 2FA is already enabled, require current code to re-setup
          if current_user.two_factor_enabled?
            render json: { error: "2FA is already enabled. Disable it first to re-setup." }, status: :conflict
            return
          end

          result = ::Auth::ManageTwoFactor.new(current_user).setup
          result[:two_factor].save!
          render json: { uri: result[:uri] }
        end

        def verify
          result = ::Auth::ManageTwoFactor.new(current_user).verify_and_enable(params[:code])
          render json: { backup_codes: result[:backup_codes] }
        rescue ::Auth::AuthError => e
          render json: { error: e.message }, status: :unprocessable_content
        end

        def validate
          # Validate 2FA code during login (using temp_token from login response)
          payload = JWT.decode(params[:temp_token], Rails.application.secret_key_base, true, algorithm: "HS256").first
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
          # Require current 2FA code or backup code to disable
          unless params[:code].present?
            render json: { error: "A valid 2FA code is required to disable 2FA" }, status: :unprocessable_content
            return
          end

          ::Auth::ManageTwoFactor.new(current_user).validate(params[:code])
          ::Auth::ManageTwoFactor.new(current_user).disable
          render json: { message: "2FA disabled" }
        rescue ::Auth::AuthError => e
          render json: { error: e.message }, status: :unauthorized
        end
      end
    end
  end
end
