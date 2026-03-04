source "https://rubygems.org"

# Framework
gem "rails", "~> 8.1.2"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"

# Solid Stack
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Auth
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-github"
gem "omniauth_openid_connect"
gem "rotp" # TOTP for 2FA
gem "webauthn"

# API
gem "rack-cors"
gem "rack-attack"
gem "hana" # RFC 6902 JSON Patch
gem "bcrypt", "~> 3.1.7"
gem "jwt"

# Storage
gem "image_processing", "~> 1.2"
gem "aws-sdk-s3", require: false

# AI
gem "ruby_llm"
gem "sqlite-vec"

# Google Sheets (RAG)
gem "google-apis-sheets_v4"

# HTTP
gem "faraday"

# Utils
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "climate_control"
end
