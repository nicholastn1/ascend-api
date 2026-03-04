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
          render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
          return
        end

        current_user.update!(password: params[:new_password])
        render json: { message: "Password updated" }
      end

      private

      def profile_params
        params.permit(:name, :username, :display_username, :image)
      end
    end
  end
end
