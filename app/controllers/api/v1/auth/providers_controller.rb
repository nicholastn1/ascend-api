module Api
  module V1
    module Auth
      class ProvidersController < BaseController
        skip_before_action :authenticate_user!

        def index
          providers = []
          providers << "email" unless ENV["DISABLE_EMAIL_AUTH"] == "true"
          providers << "google" if ENV["GOOGLE_CLIENT_ID"].present?
          providers << "github" if ENV["GITHUB_CLIENT_ID"].present?
          providers << "oidc" if ENV["CUSTOM_OIDC_ISSUER"].present?

          render json: { providers: providers }
        end
      end
    end
  end
end
