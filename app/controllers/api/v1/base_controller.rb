module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def current_user
        @current_user ||= authenticate_from_session || authenticate_from_api_key
      end

      def authenticate_user!
        render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
      end

      def authenticate_from_session
        token = cookies.signed[:session_token] || request.headers["Authorization"]&.delete_prefix("Bearer ")
        return unless token

        session_record = Session.find_by_token(token)
        return unless session_record&.active?

        session_record.user
      end

      def authenticate_from_api_key
        api_key_header = request.headers["X-API-Key"]
        return unless api_key_header

        ApiKey.authenticate(api_key_header)
      end

      def set_session_cookie(session_record)
        cookies.signed[:session_token] = session_cookie_options(session_record.raw_token || session_record.token, session_record.expires_at)
      end

      def delete_session_cookie
        cookies.delete(:session_token, session_cookie_options("", 1.day.ago).except(:value, :expires))
      end

      def session_cookie_options(value, expires_at)
        {
          value: value,
          httponly: true,
          secure: Rails.env.production?,
          same_site: Rails.env.production? ? :none : :lax,
          expires: expires_at
        }
      end

      def user_json(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          username: user.username,
          display_username: user.display_username,
          image: user.image,
          email_verified: user.email_verified,
          two_factor_enabled: user.two_factor_enabled,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
    end
  end
end
