module Api
  module V1
    module Auth
      class OauthController < BaseController
        skip_before_action :authenticate_user!

        def redirect
          provider = params[:provider]
          # Build OAuth URL and redirect
          strategy = omniauth_strategy(provider)
          redirect_to strategy[:authorize_url], allow_other_host: true
        end

        def callback
          provider = params[:provider]
          # In a real implementation, this would process the OAuth callback
          # For now, this is a placeholder that will be wired up with OmniAuth middleware
          render json: { error: "OAuth callback not yet implemented" }, status: :not_implemented
        end

        private

        def omniauth_strategy(provider)
          case provider
          when "google"
            {
              authorize_url: "https://accounts.google.com/o/oauth2/v2/auth?" + {
                client_id: ENV["GOOGLE_CLIENT_ID"],
                redirect_uri: api_v1_auth_oauth_callback_url(provider: "google"),
                response_type: "code",
                scope: "openid email profile"
              }.to_query
            }
          when "github"
            {
              authorize_url: "https://github.com/login/oauth/authorize?" + {
                client_id: ENV["GITHUB_CLIENT_ID"],
                redirect_uri: api_v1_auth_oauth_callback_url(provider: "github"),
                scope: "user:email"
              }.to_query
            }
          else
            raise ActionController::RoutingError, "Unknown provider: #{provider}"
          end
        end
      end
    end
  end
end
