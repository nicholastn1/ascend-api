module Api
  module V1
    module Auth
      class OauthController < BaseController
        skip_before_action :authenticate_user!

        def redirect
          provider = params[:provider]
          # Generate CSRF state parameter
          state = SecureRandom.hex(24)
          session[:oauth_state] = state

          strategy = omniauth_strategy(provider, state)
          redirect_to strategy[:authorize_url], allow_other_host: true
        end

        def callback
          provider = params[:provider]

          # Verify CSRF state parameter
          unless ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, session.delete(:oauth_state).to_s)
            render json: { error: "Invalid OAuth state" }, status: :unprocessable_content
            return
          end

          # In a real implementation, this would process the OAuth callback
          # For now, this is a placeholder that will be wired up with OmniAuth middleware
          render json: { error: "OAuth callback not yet implemented" }, status: :not_implemented
        end

        private

        ALLOWED_PROVIDERS = %w[google github].freeze

        def omniauth_strategy(provider, state)
          unless ALLOWED_PROVIDERS.include?(provider)
            raise ActionController::RoutingError, "Unknown provider"
          end

          case provider
          when "google"
            {
              authorize_url: "https://accounts.google.com/o/oauth2/v2/auth?" + {
                client_id: ENV["GOOGLE_CLIENT_ID"],
                redirect_uri: api_v1_auth_oauth_callback_url(provider: "google"),
                response_type: "code",
                scope: "openid email profile",
                state: state
              }.to_query
            }
          when "github"
            {
              authorize_url: "https://github.com/login/oauth/authorize?" + {
                client_id: ENV["GITHUB_CLIENT_ID"],
                redirect_uri: api_v1_auth_oauth_callback_url(provider: "github"),
                scope: "user:email",
                state: state
              }.to_query
            }
          end
        end
      end
    end
  end
end
