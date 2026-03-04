module Api
  module V1
    module Auth
      class PasskeysController < BaseController
        skip_before_action :authenticate_user!, only: %i[authenticate_options authenticate]

        def register_options
          service = ::Auth::ManagePasskeys.new(current_user)
          result = service.registration_options
          # Store challenge in session for verification
          session[:webauthn_challenge] = result[:challenge]
          render json: result[:options]
        end

        def register
          service = ::Auth::ManagePasskeys.new(current_user)
          passkey = service.register(passkey_params, session[:webauthn_challenge])
          session.delete(:webauthn_challenge)
          render json: { id: passkey.id, name: passkey.name }, status: :created
        rescue WebAuthn::Error => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def authenticate_options
          service = ::Auth::ManagePasskeys.new(nil)
          result = service.authentication_options
          session[:webauthn_challenge] = result[:challenge]
          render json: result[:options]
        end

        def authenticate
          service = ::Auth::ManagePasskeys.new(nil)
          user = service.authenticate(passkey_params, session[:webauthn_challenge])
          session.delete(:webauthn_challenge)

          user_session = user.sessions.create!(
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          )
          set_session_cookie(user_session)
          render json: user_json(user)
        rescue WebAuthn::Error, ActiveRecord::RecordNotFound => e
          render json: { error: e.message }, status: :unauthorized
        end

        def destroy
          current_user.passkeys.find(params[:id]).destroy!
          render json: { message: "Passkey removed" }
        end

        private

        def passkey_params
          params.permit(:id, :rawId, :type, :name, :authenticatorAttachment, transports: [],
            response: %i[clientDataJSON attestationObject authenticatorData signature userHandle])
        end
      end
    end
  end
end
