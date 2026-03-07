Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Health
      get "health", to: "health#show"

      # Auth
      namespace :auth do
        post "register", to: "registrations#create"
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
        get "session", to: "sessions#show"
        post "forgot-password", to: "passwords#create"
        post "reset-password", to: "passwords#update"
        post "verify-email", to: "email_verifications#create"
        get "providers", to: "providers#index"
        delete "account", to: "registrations#destroy"

        # OAuth
        get "oauth/:provider", to: "oauth#redirect", as: :oauth_redirect
        get "oauth/:provider/callback", to: "oauth#callback", as: :oauth_callback

        # 2FA
        post "two-factor/setup", to: "two_factor#setup"
        post "two-factor/verify", to: "two_factor#verify"
        post "two-factor/validate", to: "two_factor#validate"
        delete "two-factor", to: "two_factor#destroy"

        # Passkeys
        post "passkeys/register/options", to: "passkeys#register_options"
        post "passkeys/register", to: "passkeys#register"
        post "passkeys/authenticate/options", to: "passkeys#authenticate_options"
        post "passkeys/authenticate", to: "passkeys#authenticate"
        delete "passkeys/:id", to: "passkeys#destroy"

        # API Keys
        resources :api_keys, path: "api-keys", only: %i[index create update destroy]
      end

      # Profile
      get "profile", to: "profiles#show"
      put "profile", to: "profiles#update"
      put "profile/password", to: "profiles#update_password"

      # Resumes
      resources :resumes, only: %i[index create show update destroy] do
        member do
          patch :patch_data
          post :duplicate
          post :lock
          put :password, action: :set_password
          delete :password, action: :remove_password
        end

        collection do
          get :tags
          post :import
        end

        resource :statistics, only: :show, controller: "resume_statistics"
      end

      # Public resume access
      get "resumes/public/:username/:slug", to: "public_resumes#show"
      post "resumes/public/:username/:slug/verify", to: "public_resumes#verify"

      # Resume export
      get "resumes/:id/pdf", to: "resume_exports#pdf"
      get "resumes/:id/screenshot", to: "resume_exports#screenshot"

      # Job Applications
      resources :applications, only: %i[index create show update destroy] do
        member do
          post :move
        end

        collection do
          get :kanban
          get "analytics/overview", to: "application_analytics#overview"
          get "analytics/timeline", to: "application_analytics#timeline"
          get "analytics/funnel", to: "application_analytics#funnel"
          get "analytics/avg-time", to: "application_analytics#avg_time"
        end

        resources :contacts, controller: "application_contacts", only: %i[index create update destroy]
        resources :history, controller: "application_histories", only: :index
      end

      # Chat
      namespace :chat do
        resources :conversations, only: %i[index create show update destroy] do
          resources :messages, only: :create
        end
        get "rate-limit", to: "rate_limit#show"
      end

      # AI
      post "ai/test-connection", to: "ai#test_connection"
      post "ai/parse-pdf", to: "ai#parse_pdf"
      post "ai/parse-docx", to: "ai#parse_docx"
      get "ai/config", to: "ai_config#show"
      put "ai/config", to: "ai_config#update"
      post "ai/config/test", to: "ai_config#test_connection"

      # Prompts
      resources :prompts, only: %i[index show update], param: :slug

      # Knowledge Base
      resources :knowledge, only: %i[index create update destroy] do
        member do
          post :sync
        end
        collection do
          post :search
        end
      end

      # Storage
      post "storage/upload", to: "storage#upload"
      delete "storage/files", to: "storage#destroy"

      # Public
      get "flags", to: "flags#index"
      namespace :statistics do
        get "users", to: "public#users"
        get "resumes", to: "public#resumes"
      end
    end
  end
end
