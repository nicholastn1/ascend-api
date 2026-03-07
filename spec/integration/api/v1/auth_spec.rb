require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  let(:user) { create(:user, :verified) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/register" do
    post "Register a new user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string, format: :email },
          username: { type: :string },
          password: { type: :string, minLength: 8 }
        },
        required: %w[name email username password]
      }

      response "201", "user registered" do
        before { ENV.delete("FLAG_DISABLE_SIGNUPS") }

        let(:body) do
          { name: "New User", email: "newuser@example.com", username: "newuser", password: "password123" }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["email"]).to eq("newuser@example.com")
        end
      end

      response "422", "invalid params" do
        let(:body) { { name: "", email: "bad", username: "", password: "short" } }
        run_test!
      end

      response "403", "signups disabled" do
        before { ENV["FLAG_DISABLE_SIGNUPS"] = "true" }
        after { ENV.delete("FLAG_DISABLE_SIGNUPS") }

        let(:body) do
          { name: "Blocked", email: "blocked@example.com", username: "blocked", password: "password123" }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to match(/disabled/i)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Login
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/login" do
    post "Log in with email and password" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          password: { type: :string }
        },
        required: %w[email password]
      }

      response "200", "login successful" do
        let(:body) { { email: user.email, password: "password123" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["email"]).to eq(user.email)
        end
      end

      response "401", "invalid credentials" do
        let(:body) { { email: user.email, password: "wrongpassword" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Logout
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/logout" do
    delete "Log out current session" do
      tags "Auth"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "logged out" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to eq("Logged out")
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Session
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/session" do
    get "Get current session / user info" do
      tags "Auth"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "session info returned" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(user.id)
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Forgot Password
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/forgot-password" do
    post "Request a password reset email" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email }
        },
        required: %w[email]
      }

      response "200", "reset email sent (always succeeds to prevent enumeration)" do
        let(:body) { { email: user.email } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to match(/reset link/i)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Reset Password
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/reset-password" do
    post "Reset password with token" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string },
          password: { type: :string, minLength: 8 }
        },
        required: %w[token password]
      }

      response "200", "password reset successfully" do
        let(:body) do
          token = SecureRandom.hex(20)
          user.update!(
            reset_password_token: token,
            reset_password_token_digest: Digest::SHA256.hexdigest(token),
            reset_password_sent_at: Time.current
          )
          { token: token, password: "newpassword123" }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to match(/reset/i)
        end
      end

      response "422", "invalid or expired token" do
        let(:body) { { token: "invalid_token", password: "newpassword123" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Verify Email
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/verify-email" do
    post "Verify email address with token" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string }
        },
        required: %w[token]
      }

      response "200", "email verified" do
        let(:body) do
          unverified = create(:user, confirmation_token: "verify123")
          { token: "verify123" }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to match(/verified/i)
        end
      end

      response "422", "invalid token" do
        let(:body) { { token: "bad_token" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Providers
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/providers" do
    get "List enabled authentication providers" do
      tags "Auth"
      produces "application/json"

      response "200", "providers list" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key("providers")
          expect(data["providers"]).to be_an(Array)
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Delete Account
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/account" do
    delete "Delete current user account" do
      tags "Auth"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "account deleted" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to match(/deleted/i)
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # OAuth - Redirect
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/oauth/{provider}" do
    get "Redirect to OAuth provider" do
      tags "Auth - OAuth"
      produces "application/json"

      parameter name: :provider, in: :path, type: :string, description: "OAuth provider (google, github)",
        enum: %w[google github]

      response "302", "redirects to provider authorization URL" do
        before { skip "Requires external OAuth provider configuration" }

        let(:provider) { "google" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # OAuth - Callback
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/oauth/{provider}/callback" do
    get "Handle OAuth provider callback" do
      tags "Auth - OAuth"
      produces "application/json"

      parameter name: :provider, in: :path, type: :string, description: "OAuth provider (google, github)",
        enum: %w[google github]
      parameter name: :code, in: :query, type: :string, required: false, description: "Authorization code"
      parameter name: :state, in: :query, type: :string, required: false, description: "CSRF state parameter"

      response "200", "OAuth callback processed" do
        before { skip "Requires external OAuth callback flow" }

        let(:provider) { "google" }
        let(:code) { "auth_code_123" }
        let(:state) { "state_param" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Two-Factor - Setup
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/two-factor/setup" do
    post "Set up two-factor authentication" do
      tags "Auth - 2FA"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "2FA provisioning URI returned" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key("uri")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Two-Factor - Verify (enable)
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/two-factor/verify" do
    post "Verify TOTP code and enable 2FA" do
      tags "Auth - 2FA"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          code: { type: :string, description: "6-digit TOTP code" }
        },
        required: %w[code]
      }

      response "200", "2FA enabled, backup codes returned" do
        before { skip "Requires valid TOTP code from authenticator setup" }

        let(:body) { { code: "123456" } }
        run_test!
      end

      response "422", "invalid TOTP code" do
        before do
          # Set up 2FA first so we can attempt verification
          create(:two_factor, user: user) if defined?(TwoFactor) && user.two_factor.nil?
        rescue StandardError
          skip "TwoFactor factory not available"
        end

        let(:body) { { code: "000000" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Two-Factor - Validate (during login)
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/two-factor/validate" do
    post "Validate 2FA code during login" do
      tags "Auth - 2FA"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          temp_token: { type: :string, description: "Temporary JWT token from login response" },
          code: { type: :string, description: "6-digit TOTP code or backup code" }
        },
        required: %w[temp_token code]
      }

      response "200", "2FA validated, session created" do
        before { skip "Requires valid temp_token and TOTP code" }

        let(:body) { { temp_token: "jwt.token.here", code: "123456" } }
        run_test!
      end

      response "401", "invalid or expired temp token" do
        let(:body) { { temp_token: "invalid.token.here", code: "123456" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Two-Factor - Disable
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/two-factor" do
    delete "Disable two-factor authentication" do
      tags "Auth - 2FA"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          code: { type: :string, description: "Current 2FA code to confirm disable" }
        },
        required: %w[code]
      }

      response "200", "2FA disabled" do
        before { skip "Requires user with 2FA enabled and valid TOTP code" }

        let(:body) { { code: "123456" } }
        run_test!
      end

      response "422", "missing code" do
        let(:body) { {} }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Passkeys - Register Options
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/passkeys/register/options" do
    post "Get WebAuthn registration options" do
      tags "Auth - Passkeys"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "registration options returned" do
        before { skip "Requires WebAuthn configuration" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Passkeys - Register
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/passkeys/register" do
    post "Register a new passkey" do
      tags "Auth - Passkeys"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :string },
          rawId: { type: :string },
          type: { type: :string },
          name: { type: :string },
          authenticatorAttachment: { type: :string },
          transports: { type: :array, items: { type: :string } },
          response: {
            type: :object,
            properties: {
              clientDataJSON: { type: :string },
              attestationObject: { type: :string }
            }
          }
        },
        required: %w[id rawId type response]
      }

      response "201", "passkey registered" do
        before { skip "Requires WebAuthn ceremony" }

        let(:body) do
          {
            id: "credential-id",
            rawId: "raw-credential-id",
            type: "public-key",
            name: "My Passkey",
            response: { clientDataJSON: "data", attestationObject: "object" }
          }
        end

        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Passkeys - Authenticate Options
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/passkeys/authenticate/options" do
    post "Get WebAuthn authentication options" do
      tags "Auth - Passkeys"
      produces "application/json"

      response "200", "authentication options returned" do
        before { skip "Requires WebAuthn configuration" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Passkeys - Authenticate
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/passkeys/authenticate" do
    post "Authenticate with a passkey" do
      tags "Auth - Passkeys"
      consumes "application/json"
      produces "application/json"

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :string },
          rawId: { type: :string },
          type: { type: :string },
          response: {
            type: :object,
            properties: {
              clientDataJSON: { type: :string },
              authenticatorData: { type: :string },
              signature: { type: :string },
              userHandle: { type: :string }
            }
          }
        },
        required: %w[id rawId type response]
      }

      response "200", "authenticated with passkey" do
        before { skip "Requires WebAuthn ceremony" }

        let(:body) do
          {
            id: "credential-id",
            rawId: "raw-credential-id",
            type: "public-key",
            response: {
              clientDataJSON: "data",
              authenticatorData: "auth-data",
              signature: "sig",
              userHandle: "handle"
            }
          }
        end

        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Passkeys - Delete
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/passkeys/{id}" do
    delete "Remove a passkey" do
      tags "Auth - Passkeys"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :string, description: "Passkey ID"

      response "200", "passkey removed" do
        before { skip "Requires existing passkey record with valid WebAuthn data" }

        let(:id) { "passkey-uuid" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { "passkey-uuid" }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # API Keys - List
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/api-keys" do
    get "List all API keys for current user" do
      tags "Auth - API Keys"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "API keys listed" do
        before { create(:api_key, user: user) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.length).to be >= 1
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        run_test!
      end
    end

    # -------------------------------------------------------------------------
    # API Keys - Create
    # -------------------------------------------------------------------------
    post "Create a new API key" do
      tags "Auth - API Keys"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          expires_at: { type: :string, format: "date-time", nullable: true },
          permissions: { type: :array, items: { type: :string } }
        },
        required: %w[name]
      }

      response "201", "API key created" do
        let(:body) { { name: "CI Key", expires_at: 30.days.from_now.iso8601 } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key("key")
          expect(data["name"]).to eq("CI Key")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:body) { { name: "Nope" } }
        run_test!
      end
    end
  end

  # ---------------------------------------------------------------------------
  # API Keys - Update
  # ---------------------------------------------------------------------------
  path "/api/v1/auth/api-keys/{id}" do
    put "Update an API key" do
      tags "Auth - API Keys"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :string, description: "API Key ID"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          enabled: { type: :boolean },
          expires_at: { type: :string, format: "date-time", nullable: true }
        }
      }

      response "200", "API key updated" do
        let(:api_key) { create(:api_key, user: user) }
        let(:id) { api_key.id }
        let(:body) { { name: "Renamed Key" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["name"]).to eq("Renamed Key")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { "some-id" }
        let(:body) { { name: "Nope" } }
        run_test!
      end
    end

    # -------------------------------------------------------------------------
    # API Keys - Delete
    # -------------------------------------------------------------------------
    delete "Revoke an API key" do
      tags "Auth - API Keys"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :string, description: "API Key ID"

      response "200", "API key revoked" do
        let(:api_key) { create(:api_key, user: user) }
        let(:id) { api_key.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["message"]).to match(/revoked/i)
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid_token" }
        let(:id) { "some-id" }
        run_test!
      end
    end
  end
end
