module Api
  module V1
    class ProfilesController < BaseController
      def show
        render json: user_json(current_user)
      end

      def update
        current_user.update!(profile_params)
        render json: user_json(current_user)
      end

      def update_password
        unless current_user.authenticate(params[:current_password])
          render json: { error: "Current password is incorrect" }, status: :unprocessable_content
          return
        end

        unless params[:new_password].present?
          render json: { error: "New password is required" }, status: :unprocessable_content
          return
        end

        current_user.update!(password: params[:new_password])

        # Invalidate all other sessions on password change
        token = cookies.signed[:session_token] || request.headers["Authorization"]&.delete_prefix("Bearer ")
        current_session = Session.find_by_token(token)
        current_user.sessions.where.not(id: current_session&.id).destroy_all

        render json: { message: "Password updated" }
      end

      private

      def profile_params
        params.permit(:name, :username, :display_username, :image)
      end
    end
  end
end
