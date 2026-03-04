module Api
  module V1
    class FlagsController < BaseController
      skip_before_action :authenticate_user!

      def index
        render json: {
          disable_signups: flag("FLAG_DISABLE_SIGNUPS"),
          disable_email_auth: flag("FLAG_DISABLE_EMAIL_AUTH"),
          disable_update_check: flag("FLAG_DISABLE_UPDATE_CHECK"),
          disable_image_processing: flag("FLAG_DISABLE_IMAGE_PROCESSING")
        }
      end

      private

      def flag(name)
        ENV[name] == "true"
      end
    end
  end
end
