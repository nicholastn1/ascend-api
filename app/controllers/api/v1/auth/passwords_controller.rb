module Api
  module V1
    module Auth
      class PasswordsController < BaseController
        skip_before_action :authenticate_user!

        def create
          user = User.find_by(email: params[:email]&.downcase&.strip)
          if user
            token = SecureRandom.hex(20)
            token_digest = Digest::SHA256.hexdigest(token)
            user.update!(
              reset_password_token: token,
              reset_password_token_digest: token_digest,
              reset_password_sent_at: Time.current
            )
            # TODO: Send email via Action Mailer (token goes in the email link)
          end
          # Always return success to prevent email enumeration
          render json: { message: "If that email exists, a reset link has been sent" }
        end

        def update
          token_digest = Digest::SHA256.hexdigest(params[:token].to_s)
          user = User.find_by(reset_password_token_digest: token_digest)

          if user.nil? || user.reset_password_sent_at.nil? || user.reset_password_sent_at < 1.hour.ago
            render json: { error: "Invalid or expired token" }, status: :unprocessable_content
            return
          end

          user.update!(
            password: params[:password],
            reset_password_token: nil,
            reset_password_token_digest: nil,
            reset_password_sent_at: nil
          )

          # Invalidate all sessions on password reset
          user.sessions.destroy_all

          render json: { message: "Password reset successfully" }
        end
      end
    end
  end
end
