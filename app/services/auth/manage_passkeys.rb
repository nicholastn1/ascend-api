module Auth
  class ManagePasskeys
    def initialize(user)
      @user = user
    end

    def registration_options
      options = WebAuthn::Credential.options_for_create(
        user: { id: @user.id, name: @user.username, display_name: @user.display_username },
        exclude: @user.passkeys.pluck(:credential_id)
      )
      # Store challenge in a way that can be verified later
      { options: options, challenge: options.challenge }
    end

    def register(credential_params, challenge)
      credential = WebAuthn::Credential.from_create(credential_params)
      credential.verify(challenge)

      @user.passkeys.create!(
        credential_id: credential.id,
        public_key: credential.public_key,
        name: credential_params[:name] || "Passkey #{@user.passkeys.count + 1}",
        counter: credential.sign_count,
        aaguid: credential.response.aaguid,
        device_type: credential.response.authenticator_data.credential_backed_up? ? "multi_device" : "single_device",
        backed_up: credential.response.authenticator_data.credential_backed_up?,
        transports: (credential_params[:transports] || []).to_json
      )
    end

    def authentication_options(user = nil)
      allow_credentials = if user
        user.passkeys.map { |p| { id: p.credential_id, transports: p.transports_array } }
      else
        []
      end

      options = WebAuthn::Credential.options_for_get(allow: allow_credentials)
      { options: options, challenge: options.challenge }
    end

    def authenticate(credential_params, challenge)
      credential = WebAuthn::Credential.from_get(credential_params)
      passkey = Passkey.find_by!(credential_id: credential.id)

      credential.verify(
        challenge,
        public_key: passkey.public_key,
        sign_count: passkey.counter
      )

      passkey.update!(counter: credential.sign_count)
      passkey.user
    end
  end
end
